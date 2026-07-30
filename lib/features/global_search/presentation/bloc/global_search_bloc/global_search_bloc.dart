import 'dart:async' show unawaited;
import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/owner/domain/repositories/owner_repository.dart';
import 'package:construculator/libraries/tag/domain/repositories/tag_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:rxdart/rxdart.dart';

part 'global_search_event.dart';
part 'global_search_state.dart';

const Duration _kQueryDebounceDuration = Duration(milliseconds: 300);

const int _kMaxDisplayedSuggestions = 5;

/// Returns an [EventTransformer] that debounces events by [duration] and
/// switches to the latest mapper stream, cancelling any in-flight processing.
///
/// Extracted so any future event that needs the same treatment can reuse it
/// without duplicating the rxdart pipeline inline.
EventTransformer<E> _debounce<E>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);

/// Bloc for managing global search state across projects, estimations, and members.
///
/// In-flight loading flags are tracked as private instance state rather than
/// state-builder parameters, so a concurrently-handled event rebuilding the
/// state cannot stomp another handler's in-flight flag. Each fetch records a
/// generation counter; a superseded fetch (cancelled by the switchMap
/// transformer, deduplicated while in flight, or disowned by a
/// [GlobalSearchStarted] reset) bails out on completion so it can neither
/// clear a newer fetch's flag nor resurrect pre-reset data.
class GlobalSearchBloc extends Bloc<GlobalSearchEvent, GlobalSearchState> {
  static final _logger = AppLogger().tag('GlobalSearchBloc');
  final GlobalSearchRepository _repository;
  final TagRepository _tagRepository;
  final OwnerRepository _ownerRepository;

  List<String> _recentSearches = const [];

  List<String> _rawSuggestions = const [];

  bool _suggestionsFetched = false;

  bool _suggestionsLoading = false;

  int _suggestionsFetchGeneration = 0;

  String _currentQuery = '';

  // The last successfully dispatched (non-empty) search query; used to
  // re-run the search when a filter changes while results own the body.
  String? _lastPerformedQuery;

  // Whether a performed search currently owns the body surface. Tracked as a
  // durable flag rather than derived from the current state, because opening
  // a filter sheet emits the ready state (to render the sheet's option list)
  // and would otherwise clear the signal before the user applies the filter.
  bool _searchIsActive = false;

  Set<String> _selectedTags = const {};

  // Full list of available tag names fetched from TagRepository.
  List<String> _availableTags = const [];

  // Whether _availableTags has been fetched at least once, so subsequent
  // sheet openings reuse the cached list instead of refetching.
  bool _availableTagsFetched = false;

  bool _availableTagsLoading = false;

  int _availableTagsFetchGeneration = 0;

  String _tagSearchQuery = '';

  Set<String> _selectedOwnerIds = const {};

  // Full list of available owners fetched from OwnerRepository.
  List<UserProfile> _availableOwners = const [];

  // Whether _availableOwners has been fetched at least once, so subsequent
  // sheet openings reuse the cached list instead of refetching.
  bool _availableOwnersFetched = false;

  bool _availableOwnersLoading = false;

  int _availableOwnersFetchGeneration = 0;

  String _ownerSearchQuery = '';

  DateRange? _selectedDateRange;

  SearchScope _selectedScope = SearchScope.dashboard;

  // Guards every recents fetch — the initial [GlobalSearchStarted] load and
  // the reload triggered by a scope change: whichever of the two is
  // dispatched later disowns the older in-flight fetch, so a late completion
  // cannot stomp the newer scope's selection or history.
  int _recentsFetchGeneration = 0;

  GlobalSearchBloc({
    required this._repository,
    required this._tagRepository,
    required this._ownerRepository,
  }) : super(const GlobalSearchInitial()) {
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
    on<GlobalSearchOwnerFiltersApplied>(_onOwnerFiltersApplied);
    on<GlobalSearchOwnerFilterCleared>(_onOwnerFilterCleared);
    on<GlobalSearchAvailableOwnersRequested>(_onAvailableOwnersRequested);
    // Intentionally not debounced: owner filtering is in-memory (no network
    // call), so instant per-keystroke feedback is cheap and preferable.
    on<GlobalSearchOwnerSearchQueryUpdated>(_onOwnerSearchQueryUpdated);
    on<GlobalSearchDateFilterApplied>(_onDateFilterApplied);
    on<GlobalSearchDateFilterCleared>(_onDateFilterCleared);
    on<GlobalSearchScopeChanged>(_onScopeChanged);
  }

  // Returns _availableTags filtered by the current tag search query.
  List<String> _filterAvailableTags() {
    if (_tagSearchQuery.isEmpty) return _availableTags;
    final lower = _tagSearchQuery.toLowerCase();
    return _availableTags
        .where((tag) => tag.toLowerCase().contains(lower))
        .toList();
  }

  // Returns _availableOwners filtered by the current owner search query,
  // matching against the owner's full name.
  List<UserProfile> _filterAvailableOwners() {
    if (_ownerSearchQuery.isEmpty) return _availableOwners;
    final lower = _ownerSearchQuery.toLowerCase();
    return _availableOwners
        .where((owner) => owner.fullName.toLowerCase().contains(lower))
        .toList();
  }

  // Builds a GlobalSearchReady from the current internal fields.
  GlobalSearchReady _readyState() {
    return GlobalSearchReady(
      recentSearches: _recentSearches,
      query: _currentQuery,
      suggestions: _filterSuggestions(_currentQuery),
      suggestionsLoading: _suggestionsLoading,
      selectedTags: _selectedTags,
      availableTags: _filterAvailableTags(),
      availableTagsLoading: _availableTagsLoading,
      selectedOwnerIds: _selectedOwnerIds,
      availableOwners: _filterAvailableOwners(),
      availableOwnersLoading: _availableOwnersLoading,
      selectedDateRange: _selectedDateRange,
      selectedScope: _selectedScope,
    );
  }

  Future<void> _onAvailableTagsRequested(
    GlobalSearchAvailableTagsRequested event,
    Emitter<GlobalSearchState> emit,
  ) async {
    _tagSearchQuery = '';
    // _availableTagsLoading also gates: a request arriving while a fetch is
    // in flight must not start a duplicate fetch, whose earlier completion
    // would clear the loading flag while the later fetch is still running.
    if (_availableTagsFetched || _availableTagsLoading) {
      emit(_readyState());
      return;
    }

    final generation = ++_availableTagsFetchGeneration;
    _availableTagsLoading = true;
    emit(_readyState());

    final result = await _tagRepository.getTags();
    // A GlobalSearchStarted reset disowned this fetch while it was in
    // flight; the reset handler owns the loading flag now.
    if (generation != _availableTagsFetchGeneration) return;
    _availableTagsLoading = false;

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
    // Reset the scope eagerly, before the await, so a failed reload cannot
    // carry a stale selection forward; _onScopeChanged resets it the same way.
    // This unguarded write is safe only while GlobalSearchStarted is
    // dispatched exactly once, at bloc creation, before any UI can race it;
    // a re-dispatch (e.g. a future reset-all affordance) would silently
    // clobber a scope the user has already applied.
    _selectedScope = event.scope;
    // Captured before the await, like _onScopeChanged: a scope change
    // dispatched while this fetch is in flight takes ownership of the scope
    // and history, and this fetch's late completion must not clobber it.
    final generation = ++_recentsFetchGeneration;
    final result = await _repository.getRecentSearches(event.scope);
    // A scope change (or a newer reset) disowned this fetch while it was in
    // flight; its owner will populate the history.
    if (generation != _recentsFetchGeneration) return;
    result.fold(
        (failure) => emit(GlobalSearchRecentsLoadFailure(failure: failure)), (
      recentSearches,
    ) {
      _recentSearches = recentSearches;
      _rawSuggestions = const [];
      _suggestionsFetched = false;
      _suggestionsLoading = false;
      // Disown any in-flight fetch: its completion must not resurrect the
      // pre-reset cache, mark data as fetched, or touch a loading flag the
      // reset now owns.
      _suggestionsFetchGeneration++;
      _currentQuery = '';
      _selectedTags = const {};
      _tagSearchQuery = '';
      _availableTags = const [];
      _availableTagsFetched = false;
      _availableTagsLoading = false;
      _availableTagsFetchGeneration++;
      _lastPerformedQuery = null;
      _searchIsActive = false;
      _selectedOwnerIds = const {};
      _ownerSearchQuery = '';
      _availableOwners = const [];
      _availableOwnersFetched = false;
      _availableOwnersLoading = false;
      _availableOwnersFetchGeneration++;
      _selectedDateRange = null;
      emit(_readyState());
    });
  }

  Future<void> _onScopeChanged(
    GlobalSearchScopeChanged event,
    Emitter<GlobalSearchState> emit,
  ) async {
    if (event.scope == _selectedScope) return;
    _selectedScope = event.scope;
    emit(_readyState());
    _reRunActiveSearch();

    // Recent searches are stored per scope, so switching scope reloads the
    // history for the newly selected one.
    final generation = ++_recentsFetchGeneration;
    final result = await _repository.getRecentSearches(event.scope);
    // A reset or a newer scope change disowned this reload while it was in
    // flight; its owner will populate the history.
    if (generation != _recentsFetchGeneration) return;
    result.fold(
      (failure) {
        // Keep the previous scope's history visible rather than blanking the
        // list; the toast surfaces the failure.
        emit(GlobalSearchRecentsLoadFailure(failure: failure));
        emit(_readyState());
      },
      (recentSearches) {
        _recentSearches = recentSearches;
        emit(_readyState());
      },
    );
  }

  Future<void> _onQueryUpdated(
    GlobalSearchQueryUpdated event,
    Emitter<GlobalSearchState> emit,
  ) async {
    final trimmedQuery = event.query.trim();
    _currentQuery = trimmedQuery;
    // Editing the query returns to the suggestions/recents surface; a filter
    // change must no longer resurrect the previous results.
    _searchIsActive = false;

    if (trimmedQuery.isEmpty) {
      // Clearing the query cancels any same-pipeline suggestions fetch via
      // the switchMap transformer, so that handler can no longer emit its
      // completion. Reset the flag here so this emission doesn't report a
      // loading fetch that will never complete visibly.
      _suggestionsLoading = false;
      emit(_readyState());
      return;
    }

    if (!_suggestionsFetched) {
      await _fetchAndEmitSuggestions(emit);
      return;
    }

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
    _lastPerformedQuery = trimmedQuery;
    _searchIsActive = true;
    emit(GlobalSearchLoadInProgress(query: trimmedQuery));

    final result = await _repository.search(
      SearchParams(
        query: trimmedQuery,
        scope: _selectedScope,
        // SearchParams accepts a single tag; sort for deterministic selection
        // until CA-638 extends the API to support multi-tag filtering.
        filterByTag: _selectedTags.isEmpty
            ? null
            : (_selectedTags.toList()..sort()).first,
        // Sorted so equal selections always produce the same RPC payload.
        filterByOwners: _selectedOwnerIds.isEmpty
            ? null
            : (_selectedOwnerIds.toList()..sort()),
        filterByDateFrom: _selectedDateRange?.start,
        filterByDateTo: _selectedDateRange?.end,
      ),
    );

    result.fold(
        (failure) => emit(
              GlobalSearchLoadFailure(failure: failure, query: trimmedQuery),
            ), (
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
            .saveRecentSearch(
              trimmedQuery,
              _selectedScope,
              hasResults: hasResults,
            )
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
    await _fetchAndEmitSuggestions(emit);
  }

  Future<void> _fetchAndEmitSuggestions(
    Emitter<GlobalSearchState> emit,
  ) async {
    final generation = ++_suggestionsFetchGeneration;
    _suggestionsLoading = true;
    emit(_readyState());

    final result = await _repository.getSearchSuggestions();
    if (generation != _suggestionsFetchGeneration) return;
    _suggestionsLoading = false;

    result.fold(
      (failure) {
        emit(GlobalSearchSuggestionsLoadFailure(failure: failure));
        emit(_readyState());
      },
      (suggestions) {
        _rawSuggestions = suggestions;
        _suggestionsFetched = true;
        emit(_readyState());
      },
    );
  }

  List<String> _filterSuggestions(String query) {
    if (query.isEmpty) return const [];
    final lower = query.toLowerCase();
    return _rawSuggestions
        .where((s) => s.toLowerCase().startsWith(lower))
        .take(_kMaxDisplayedSuggestions)
        .toList();
  }

  // Re-dispatches the last performed search so a filter change is
  // reflected in the visible results instead of leaving them stale.
  void _reRunActiveSearch() {
    final query = _lastPerformedQuery;
    if (!_searchIsActive || query == null) return;
    add(GlobalSearchPerformed(query: query));
  }

  void _onTagFiltersApplied(
    GlobalSearchTagFiltersApplied event,
    Emitter<GlobalSearchState> emit,
  ) {
    _selectedTags = Set.unmodifiable(event.tags);
    emit(_readyState());
    _reRunActiveSearch();
  }

  void _onTagFilterCleared(
    GlobalSearchTagFilterCleared event,
    Emitter<GlobalSearchState> emit,
  ) {
    _selectedTags = Set.unmodifiable(
      _selectedTags.where((t) => t != event.tag),
    );
    emit(_readyState());
    _reRunActiveSearch();
  }

  Future<void> _onAvailableOwnersRequested(
    GlobalSearchAvailableOwnersRequested event,
    Emitter<GlobalSearchState> emit,
  ) async {
    _ownerSearchQuery = '';
    // _availableOwnersLoading also gates: a request arriving while a fetch is
    // in flight must not start a duplicate fetch, whose earlier completion
    // would clear the loading flag while the later fetch is still running.
    if (_availableOwnersFetched || _availableOwnersLoading) {
      emit(_readyState());
      return;
    }

    final generation = ++_availableOwnersFetchGeneration;
    _availableOwnersLoading = true;
    emit(_readyState());

    final result = await _ownerRepository.getOwners();
    // A GlobalSearchStarted reset disowned this fetch while it was in
    // flight; the reset handler owns the loading flag now.
    if (generation != _availableOwnersFetchGeneration) return;
    _availableOwnersLoading = false;

    result.fold(
      (failure) {
        emit(GlobalSearchOwnersLoadFailure(failure: failure));
        emit(_readyState());
      },
      (owners) {
        _availableOwners = List.unmodifiable(owners);
        _availableOwnersFetched = true;
        emit(_readyState());
      },
    );
  }

  void _onOwnerSearchQueryUpdated(
    GlobalSearchOwnerSearchQueryUpdated event,
    Emitter<GlobalSearchState> emit,
  ) {
    _ownerSearchQuery = event.query.trim();
    emit(_readyState());
  }

  void _onOwnerFiltersApplied(
    GlobalSearchOwnerFiltersApplied event,
    Emitter<GlobalSearchState> emit,
  ) {
    _selectedOwnerIds = Set.unmodifiable(event.ownerIds);
    emit(_readyState());
    _reRunActiveSearch();
  }

  void _onOwnerFilterCleared(
    GlobalSearchOwnerFilterCleared event,
    Emitter<GlobalSearchState> emit,
  ) {
    _selectedOwnerIds = Set.unmodifiable(
      _selectedOwnerIds.where((id) => id != event.ownerId),
    );
    emit(_readyState());
    _reRunActiveSearch();
  }

  void _onDateFilterApplied(
    GlobalSearchDateFilterApplied event,
    Emitter<GlobalSearchState> emit,
  ) {
    _selectedDateRange = event.range;
    emit(_readyState());
    _reRunActiveSearch();
  }

  void _onDateFilterCleared(
    GlobalSearchDateFilterCleared event,
    Emitter<GlobalSearchState> emit,
  ) {
    _selectedDateRange = null;
    emit(_readyState());
    _reRunActiveSearch();
  }
}
