import 'dart:async' show unawaited;
import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/tag/domain/repositories/tag_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'global_search_event.dart';
part 'global_search_state.dart';

/// Debounce duration applied to [GlobalSearchQueryUpdated] events.
/// Kept here so the BLoC owns the contract — no UI-side debouncing required.
const Duration _kQueryDebounceDuration = Duration(milliseconds: 300);

/// Returns an [EventTransformer] that debounces events by [duration] and
/// switches to the latest mapper stream, cancelling any in-flight processing.
///
/// Extracted so any future event that needs the same treatment can reuse it
/// without duplicating the rxdart pipeline inline.
EventTransformer<E> _debounce<E>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);

/// Bloc for managing global search state across projects, estimations, and members
class GlobalSearchBloc extends Bloc<GlobalSearchEvent, GlobalSearchState> {
  static final _logger = AppLogger().tag('GlobalSearchBloc');
  final GlobalSearchRepository _repository;
  final TagRepository _tagRepository;

  List<String> _recentSearches = const [];

  List<String> _suggestions = const [];

  String _currentQuery = '';

  Set<String> _selectedTags = const {};

  // Full list of available tag names fetched from TagRepository.
  List<String> _availableTags = const [];

  // Whether _availableTags has been fetched at least once, so subsequent
  // sheet openings reuse the cached list instead of refetching.
  bool _availableTagsFetched = false;

  String _tagSearchQuery = '';

  GlobalSearchBloc({
    required GlobalSearchRepository repository,
    required TagRepository tagRepository,
  }) : _repository = repository,
       _tagRepository = tagRepository,
       super(const GlobalSearchInitial()) {
    on<GlobalSearchStarted>(_onStarted);
    on<GlobalSearchQueryUpdated>(
      _onQueryUpdated,
      // Debounce at the BLoC level so the UI can dispatch on every keystroke
      // without triggering redundant state emissions.
      transformer: _debounce(_kQueryDebounceDuration),
    );
    on<GlobalSearchPerformed>(_onPerformed);
    on<GlobalSearchRecentRemoved>(_onRecentRemoved);
    on<GlobalSearchSuggestionsRequested>(_onSuggestionsRequested);
    on<GlobalSearchTagFiltersApplied>(_onTagFiltersApplied);
    on<GlobalSearchTagFilterCleared>(_onTagFilterCleared);
    on<GlobalSearchAvailableTagsRequested>(_onAvailableTagsRequested);
    // Intentionally not debounced: tag filtering is in-memory (no network
    // call), so instant per-keystroke feedback is cheap and preferable.
    on<GlobalSearchTagSearchQueryUpdated>(_onTagSearchQueryUpdated);
  }

  // Returns _availableTags filtered by the current tag search query.
  List<String> _filterAvailableTags() {
    if (_tagSearchQuery.isEmpty) return _availableTags;
    final lower = _tagSearchQuery.toLowerCase();
    return _availableTags
        .where((tag) => tag.toLowerCase().contains(lower))
        .toList();
  }

  // Builds a GlobalSearchReady from the current internal fields.
  GlobalSearchReady _readyState({
    bool suggestionsLoading = false,
    bool availableTagsLoading = false,
  }) {
    return GlobalSearchReady(
      recentSearches: _recentSearches,
      query: _currentQuery,
      suggestions: _suggestions,
      suggestionsLoading: suggestionsLoading,
      selectedTags: _selectedTags,
      availableTags: _filterAvailableTags(),
      availableTagsLoading: availableTagsLoading,
    );
  }

  Future<void> _onAvailableTagsRequested(
    GlobalSearchAvailableTagsRequested event,
    Emitter<GlobalSearchState> emit,
  ) async {
    _tagSearchQuery = '';
    if (_availableTagsFetched) {
      emit(_readyState());
      return;
    }

    emit(_readyState(availableTagsLoading: true));

    final result = await _tagRepository.getTags();

    result.fold(
      (failure) {
        emit(GlobalSearchTagsLoadFailure(failure: failure));
        emit(_readyState());
      },
      (tags) {
        _availableTags = List.unmodifiable(tags.map((tag) => tag.name));
        _availableTagsFetched = true;
        emit(_readyState());
      },
    );
  }

  void _onTagSearchQueryUpdated(
    GlobalSearchTagSearchQueryUpdated event,
    Emitter<GlobalSearchState> emit,
  ) {
    _tagSearchQuery = event.query.trim();
    emit(_readyState());
  }

  Future<void> _onStarted(
    GlobalSearchStarted event,
    Emitter<GlobalSearchState> emit,
  ) async {
    final result = await _repository.getRecentSearches(event.scope);
    result.fold((failure) => emit(GlobalSearchLoadFailure(failure: failure)), (
      recentSearches,
    ) {
      _recentSearches = recentSearches;
      _suggestions = const [];
      _currentQuery = '';
      _selectedTags = const {};
      _tagSearchQuery = '';
      emit(_readyState());
    });
  }

  void _onQueryUpdated(
    GlobalSearchQueryUpdated event,
    Emitter<GlobalSearchState> emit,
  ) {
    _currentQuery = event.query;
    emit(_readyState());
  }

  Future<void> _onPerformed(
    GlobalSearchPerformed event,
    Emitter<GlobalSearchState> emit,
  ) async {
    final trimmedQuery = event.query.trim();
    if (trimmedQuery.isEmpty) {
      emit(const GlobalSearchEmptyQuery());
      return;
    }
    _currentQuery = trimmedQuery;
    emit(GlobalSearchLoadInProgress(query: trimmedQuery));

    final result = await _repository.search(
      SearchParams(
        query: trimmedQuery,
        scope: event.scope,
        // SearchParams accepts a single tag; sort for deterministic selection
        // until CA-638 extends the API to support multi-tag filtering.
        filterByTag: _selectedTags.isEmpty
            ? null
            : (_selectedTags.toList()..sort()).first,
      ),
    );

    result.fold((failure) => emit(GlobalSearchLoadFailure(failure: failure)), (
      searchResults,
    ) {
      final hasResults =
          searchResults.projects.isNotEmpty ||
          searchResults.estimations.isNotEmpty ||
          searchResults.members.isNotEmpty;

      if (hasResults) {
        emit(GlobalSearchLoadSuccess(results: searchResults));
      } else {
        emit(GlobalSearchLoadEmpty(query: trimmedQuery));
      }

      if (!_recentSearches.contains(trimmedQuery)) {
        _recentSearches = [trimmedQuery, ..._recentSearches];
      }

      // Non-blocking: persistence runs after results are shown.
      // Do NOT call emit() inside this callback — the Emitter is already
      // closed when _onPerformed returns.
      unawaited(
        _repository
            .saveRecentSearch(trimmedQuery, event.scope, hasResults: hasResults)
            .then(
              (saveResult) => saveResult.fold(
                (_) => _logger.warning(
                  'Recent search save failed silently (non-blocking; search results already shown)',
                ),
                (_) {},
              ),
            ),
      );
    });
  }

  Future<void> _onRecentRemoved(
    GlobalSearchRecentRemoved event,
    Emitter<GlobalSearchState> emit,
  ) async {
    final result = await _repository.deleteRecentSearch(
      event.searchTerm,
      event.scope,
    );

    result.fold(
      (failure) => emit(GlobalSearchRecentDeleteFailure(failure: failure)),
      (_) {
        _recentSearches = List<String>.from(_recentSearches)
          ..removeWhere((term) => term == event.searchTerm);
        emit(_readyState());
      },
    );
  }

  Future<void> _onSuggestionsRequested(
    GlobalSearchSuggestionsRequested event,
    Emitter<GlobalSearchState> emit,
  ) async {
    emit(_readyState(suggestionsLoading: true));

    final result = await _repository.getSearchSuggestions();

    result.fold(
      (failure) => emit(GlobalSearchSuggestionsLoadFailure(failure: failure)),
      (suggestions) {
        _suggestions = suggestions;
        emit(_readyState());
      },
    );
  }

  void _onTagFiltersApplied(
    GlobalSearchTagFiltersApplied event,
    Emitter<GlobalSearchState> emit,
  ) {
    _selectedTags = Set.unmodifiable(event.tags);
    emit(_readyState());
  }

  void _onTagFilterCleared(
    GlobalSearchTagFilterCleared event,
    Emitter<GlobalSearchState> emit,
  ) {
    _selectedTags = Set.unmodifiable(
      _selectedTags.where((t) => t != event.tag),
    );
    emit(_readyState());
  }
}
