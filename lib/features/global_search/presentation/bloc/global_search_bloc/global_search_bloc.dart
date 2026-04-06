import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'global_search_event.dart';
part 'global_search_state.dart';

/// Bloc for managing global search state across projects, estimations, and members
class GlobalSearchBloc extends Bloc<GlobalSearchEvent, GlobalSearchState> {
  static final _logger = AppLogger().tag('GlobalSearchBloc');
  final GlobalSearchRepository _repository;

  List<String> _recentSearches = const [];

  List<String> _suggestions = const [];

  String _currentQuery = '';

  GlobalSearchBloc({required GlobalSearchRepository repository})
    : _repository = repository,
      super(const GlobalSearchInitial()) {
    on<GlobalSearchStarted>(_onStarted);
    on<GlobalSearchQueryUpdated>(_onQueryUpdated);
    on<GlobalSearchPerformed>(_onPerformed);
    on<GlobalSearchRecentRemoved>(_onRecentRemoved);
    on<GlobalSearchSuggestionsRequested>(_onSuggestionsRequested);
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
      emit(
        GlobalSearchInitial(
          recentSearches: recentSearches,
          query: '',
          suggestions: const [],
          suggestionsLoading: false,
        ),
      );
    });
  }

  void _onQueryUpdated(
    GlobalSearchQueryUpdated event,
    Emitter<GlobalSearchState> emit,
  ) {
    _currentQuery = event.query;
    emit(
      GlobalSearchInitial(
        recentSearches: _recentSearches,
        query: event.query,
        suggestions: _suggestions,
        suggestionsLoading: false,
      ),
    );
  }

  Future<void> _onPerformed(
    GlobalSearchPerformed event,
    Emitter<GlobalSearchState> emit,
  ) async {
    _currentQuery = event.query;
    emit(GlobalSearchLoadInProgress(query: event.query));

    final result = await _repository.search(
      SearchParams(query: event.query, scope: event.scope),
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
        emit(GlobalSearchLoadEmpty(query: event.query));
      }

      if (!_recentSearches.contains(event.query)) {
        _recentSearches = [event.query, ..._recentSearches];
      }

      _repository
          .saveRecentSearch(
            event.query,
            event.scope,
            hasResults: hasResults,
          )
          .then(
            (saveResult) => saveResult.fold(
              (_) => _logger.warning(
                'Recent search save failed silently (non-blocking; search results already shown)',
              ),
              (_) {},
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
        emit(
          GlobalSearchInitial(
            recentSearches: _recentSearches,
            query: _currentQuery,
            suggestions: _suggestions,
            suggestionsLoading: false,
          ),
        );
      },
    );
  }

  Future<void> _onSuggestionsRequested(
    GlobalSearchSuggestionsRequested event,
    Emitter<GlobalSearchState> emit,
  ) async {
    emit(
      GlobalSearchInitial(
        recentSearches: _recentSearches,
        query: _currentQuery,
        suggestions: _suggestions,
        suggestionsLoading: true,
      ),
    );

    final result = await _repository.getSearchSuggestions();

    result.fold(
      (failure) => emit(GlobalSearchSuggestionsLoadFailure(failure: failure)),
      (suggestions) {
        _suggestions = suggestions;
        emit(
          GlobalSearchInitial(
            recentSearches: _recentSearches,
            query: _currentQuery,
            suggestions: suggestions,
            suggestionsLoading: false,
          ),
        );
      },
    );
  }
}
