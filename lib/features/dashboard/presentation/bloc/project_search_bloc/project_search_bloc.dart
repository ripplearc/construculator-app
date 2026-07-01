import 'dart:async';

import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_search_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'project_search_event.dart';
part 'project_search_state.dart';

const Duration _kQueryDebounceDuration = Duration(milliseconds: 300);

/// Upper bound on the cached recents list to prevent unbounded growth.
const int _kMaxCachedRecents = 20;

/// Maximum number of suggestions shown for a given query. The raw list
/// fetched from the repository may be longer; the cap keeps the dropdown
/// short, matching Global Search's `_kMaxDisplayedSuggestions`.
const int _kMaxDisplayedSuggestions = 5;

EventTransformer<E> _debounce<E>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);

/// BLoC for managing project search state on the dashboard.
///
/// Handles debounced query updates and explicit search submissions, plus the
/// recent-searches and suggestions surfaces shown on the idle state.
/// Delegates to [ProjectSearchRepository] and maps results to typed states.
class ProjectSearchBloc extends Bloc<ProjectSearchEvent, ProjectSearchState> {
  final ProjectSearchRepository _repository;
  final AuthManager _authManager;
  static final _logger = AppLogger().tag('ProjectSearchBloc');

  List<String> _cachedRecents = const [];
  List<String> _cachedSuggestions = const [];
  String _currentQuery = '';

  // Whether _cachedSuggestions has been fetched at least once for the
  // current page session, so subsequent keystrokes only re-filter locally
  // instead of re-fetching from the repository.
  bool _suggestionsFetched = false;

  /// Exposed for testing only — resolves when the last save-after-search
  /// completes, allowing tests to await it instead of using wall-clock waits.
  @visibleForTesting
  Future<void>? lastSaveCompleted;

  /// Creates a [ProjectSearchBloc] with the given [repository] and [authManager].
  ProjectSearchBloc({
    required ProjectSearchRepository repository,
    required AuthManager authManager,
  }) : _repository = repository,
       _authManager = authManager,
       super(const ProjectSearchInitial()) {
    on<ProjectSearchQueryUpdatedEvent>(
      (event, emit) => _handleQuery(event.query, emit),
      transformer: _debounce(_kQueryDebounceDuration),
    );
    on<ProjectSearchPerformedEvent>(_onPerformed);
    on<ProjectSearchHistoryRequestedEvent>(_onHistoryRequested);
    on<ProjectSearchHistoryItemDismissedEvent>(_onHistoryItemDismissed);
  }

  Future<void> _handleQuery(
    String query,
    Emitter<ProjectSearchState> emit,
  ) async {
    _currentQuery = query;

    if (query.isEmpty) {
      // Clearing the field restores the history surface rather than blanking it.
      emit(_initialFromCache());
      return;
    }

    // Typing filters the suggestions surface locally; it does not trigger a
    // live remote search. ProjectSearchPerformedEvent (submit) does that.
    if (!_suggestionsFetched) {
      await _fetchAndEmitSuggestions(emit);
      return;
    }

    emit(_initialFromCache());
  }

  Future<void> _fetchAndEmitSuggestions(Emitter<ProjectSearchState> emit) async {
    final userId = _authManager.getCurrentCredentials().data?.id;
    if (userId == null || userId.isEmpty) {
      _logger.warning('Suggestions fetch aborted: no authenticated user');
      emit(_initialFromCache());
      return;
    }

    emit(_initialFromCache(suggestionsLoading: true));

    final result = await _repository.getProjectSearchSuggestions(
      userId: userId,
    );
    result.fold(
      (failure) => _logger.warning(
        'Failed to load project search suggestions: $failure',
      ),
      (suggestions) {
        _cachedSuggestions = suggestions;
        _suggestionsFetched = true;
      },
    );

    emit(_initialFromCache());
  }

  // Filters _cachedSuggestions to terms that start with [query]
  // (case-insensitive) and caps the result at _kMaxDisplayedSuggestions.
  List<String> _filterSuggestions(String query) {
    if (query.isEmpty) return const [];
    final lower = query.toLowerCase();
    return _cachedSuggestions
        .where((s) => s.toLowerCase().startsWith(lower))
        .take(_kMaxDisplayedSuggestions)
        .toList();
  }

  Future<void> _onPerformed(
    ProjectSearchPerformedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(const ProjectSearchInitial());
      return;
    }
    await _executeSearch(event.query, emit);
  }

  Future<void> _onHistoryRequested(
    ProjectSearchHistoryRequestedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    // Reset per-session suggestion state — a fresh page open re-fetches
    // suggestions lazily on the user's first keystroke, matching Global
    // Search's GlobalSearchStarted behavior.
    _currentQuery = '';
    _cachedSuggestions = const [];
    _suggestionsFetched = false;

    final userId = _authManager.getCurrentCredentials().data?.id;
    if (userId == null || userId.isEmpty) {
      _logger.warning('History request aborted: no authenticated user');
      emit(const ProjectSearchInitial());
      return;
    }

    emit(
      ProjectSearchInitial(recentSearches: _cachedRecents, isLoadingHistory: true),
    );

    final result = await _repository.getRecentProjectSearches(userId: userId);

    // On failure, keep the previously cached value so a transient network
    // hiccup does not blank the history surface.
    _cachedRecents = result.fold<List<String>>(
      (failure) {
        _logger.warning('Failed to load recent project searches: $failure');
        return _cachedRecents;
      },
      (terms) => terms,
    );

    emit(_initialFromCache());
  }

  Future<void> _onHistoryItemDismissed(
    ProjectSearchHistoryItemDismissedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    final userId = _authManager.getCurrentCredentials().data?.id;
    if (userId == null || userId.isEmpty) {
      _logger.warning('History dismiss aborted: no authenticated user');
      return;
    }

    final result = await _repository.deleteRecentProjectSearch(
      userId: userId,
      searchTerm: event.searchTerm,
    );

    result.fold(
      (failure) {
        _logger.warning(
          'Failed to delete recent project search "${event.searchTerm}": $failure',
        );
      },
      (_) => _removeDismissedTermAndEmit(event.searchTerm, emit),
    );
  }

  void _removeDismissedTermAndEmit(
    String searchTerm,
    Emitter<ProjectSearchState> emit,
  ) {
    final normalized = searchTerm.toLowerCase().trim();
    _cachedRecents = _cachedRecents
        .where((term) => term.toLowerCase().trim() != normalized)
        .toList(growable: false);
    if (state is ProjectSearchInitial) {
      emit(_initialFromCache());
    }
  }

  Future<void> _executeSearch(
    String query,
    Emitter<ProjectSearchState> emit,
  ) async {
    final userId = _authManager.getCurrentCredentials().data?.id;
    if (userId == null || userId.isEmpty) {
      _logger.warning('Project search aborted: no authenticated user');
      emit(
        ProjectSearchFailureState(
          failure: const AuthFailure(errorType: AuthErrorType.userNotFound),
          query: query,
        ),
      );
      return;
    }

    emit(ProjectSearchLoading(query: query));

    final result = await _repository.searchProjects(
      userId: userId,
      query: query,
    );

    result.fold(
      (failure) {
        _logger.warning('Project search failed: $failure');
        emit(ProjectSearchFailureState(failure: failure, query: query));
        // Skip history save on failure — backend has_results contract requires
        // a confirmed result set.
      },
      (projects) {
        emit(ProjectSearchResultsLoaded(results: projects, query: query));
        lastSaveCompleted = _saveSearchToHistory(
          userId: userId,
          query: query,
          hasResults: projects.isNotEmpty,
        );
        unawaited(lastSaveCompleted!);
      },
    );
  }

  Future<void> _saveSearchToHistory({
    required String userId,
    required String query,
    required bool hasResults,
  }) async {
    final saveResult = await _repository.saveRecentProjectSearch(
      userId: userId,
      searchTerm: query,
      hasResults: hasResults,
    );
    saveResult.fold(
      (failure) {
        _logger.warning(
          'Failed to save recent project search "$query": $failure',
        );
      },
      (_) {
        // Cache stores terms normalised to lowercase; repository receives the original-case query.
        final normalized = query.toLowerCase().trim();
        if (normalized.isEmpty) return;
        final updated = <String>[
          normalized,
          ..._cachedRecents.where(
            (term) => term.toLowerCase().trim() != normalized,
          ),
        ];
        if (updated.length > _kMaxCachedRecents) {
          _cachedRecents = updated.sublist(0, _kMaxCachedRecents);
        } else {
          _cachedRecents = updated;
        }
      },
    );
  }

  ProjectSearchInitial _initialFromCache({bool suggestionsLoading = false}) =>
      ProjectSearchInitial(
        recentSearches: _cachedRecents,
        suggestions: _filterSuggestions(_currentQuery),
        query: _currentQuery,
        suggestionsLoading: suggestionsLoading,
      );
}
