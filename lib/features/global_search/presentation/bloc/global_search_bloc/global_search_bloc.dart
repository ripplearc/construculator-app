import 'dart:async';

import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/usecases/delete_recent_search_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/get_recent_searches_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/get_search_suggestions_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/perform_search_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/save_recent_search_use_case.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'global_search_event.dart';
part 'global_search_state.dart';

/// BLoC that manages state for the global search feature.
///
/// Responsibilities:
/// - Loads the user's recent search history on initialization.
  /// - Reflects query text changes synchronously (no network call per keystroke).
  ///   The UI is responsible for debouncing [GlobalSearchQueryUpdated] before
  ///   dispatching it (see event doc for details).
  /// - Executes full searches across projects, estimations, and members on submit.
  /// - Persists successful search terms to history as a fire-and-forget side effect.
  /// - Loads personalized suggestions when requested by the UI.
  /// - Removes terms from recent history when the user dismisses them.
class GlobalSearchBloc extends Bloc<GlobalSearchEvent, GlobalSearchState> {
  final PerformSearchUseCase _performSearchUseCase;
  final GetRecentSearchesUseCase _getRecentSearchesUseCase;
  final SaveRecentSearchUseCase _saveRecentSearchUseCase;
  final DeleteRecentSearchUseCase _deleteRecentSearchUseCase;
  final GetSearchSuggestionsUseCase _getSearchSuggestionsUseCase;

  /// Cached recent searches so [GlobalSearchQueryUpdated] can restore them
  /// without a round-trip to the repository.
  List<String> _recentSearches = const [];

  /// Cached suggestions from the last successful suggestions load.
  List<String> _suggestions = const [];

  /// Last known query text for the search field.
  String _currentQuery = '';

  GlobalSearchBloc({
    required PerformSearchUseCase performSearchUseCase,
    required GetRecentSearchesUseCase getRecentSearchesUseCase,
    required SaveRecentSearchUseCase saveRecentSearchUseCase,
    required DeleteRecentSearchUseCase deleteRecentSearchUseCase,
    required GetSearchSuggestionsUseCase getSearchSuggestionsUseCase,
  }) : _performSearchUseCase = performSearchUseCase,
       _getRecentSearchesUseCase = getRecentSearchesUseCase,
       _saveRecentSearchUseCase = saveRecentSearchUseCase,
       _deleteRecentSearchUseCase = deleteRecentSearchUseCase,
       _getSearchSuggestionsUseCase = getSearchSuggestionsUseCase,
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
    final result = await _getRecentSearchesUseCase(event.scope);
    result.fold((failure) => emit(GlobalSearchLoadFailure(failure: failure)), (
      recentSearches,
    ) {
      _recentSearches = recentSearches;
      _suggestions = const [];
      emit(
        GlobalSearchInitial(
          recentSearches: recentSearches,
          query: _currentQuery,
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

    final result = await _performSearchUseCase(
      SearchParams(query: event.query),
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

      unawaited(
        _saveRecentSearchUseCase(
          event.query,
          event.scope,
          hasResults: hasResults,
        ),
      );
    });
  }

  Future<void> _onRecentRemoved(
    GlobalSearchRecentRemoved event,
    Emitter<GlobalSearchState> emit,
  ) async {
    final result = await _deleteRecentSearchUseCase(
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

    final result = await _getSearchSuggestionsUseCase();

    result.fold(
      (failure) =>
          emit(GlobalSearchSuggestionsLoadFailure(failure: failure)),
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
