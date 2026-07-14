import 'dart:async';

import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/owner/domain/repositories/owner_repository.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_search_repository.dart';
import 'package:construculator/libraries/search_filters/domain/entities/date_range.dart';
import 'package:construculator/libraries/tag/domain/repositories/tag_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'project_search_event.dart';
part 'project_search_state.dart';

const Duration _kQueryDebounceDuration = Duration(milliseconds: 300);

const int _kMaxCachedRecents = 20;

const int _kMaxDisplayedSuggestions = 5;

EventTransformer<E> _debounce<E>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);

// Restartable semantics: a re-dispatch cancels the in-flight handler, so
// rapidly reopening a filter sheet cannot fire two concurrent fetches whose
// interleaved results would surface a stray failure toast after a success.
EventTransformer<E> _restartable<E>() =>
    (events, mapper) => events.switchMap(mapper);

/// BLoC for managing project search state on the dashboard.
///
/// Handles debounced query updates and explicit search submissions, plus the
/// recent-searches and suggestions surfaces shown on the idle state, and the
/// Tags / Owner / Modified-date filter chips. Selected filters are threaded
/// into [ProjectSearchRepository.searchProjects] on the next search.
/// Delegates to [ProjectSearchRepository] and maps results to typed states.
///
/// The in-flight suggestions loading flag is tracked as private instance
/// state rather than a state-builder parameter, so a concurrently-handled
/// event rebuilding the state cannot stomp it. A fetch-generation counter
/// lets a superseded fetch (cancelled by the switchMap transformer or
/// disowned by a history-request reset) bail out on completion instead of
/// clearing a newer fetch's flag or resurrecting pre-reset data.
class ProjectSearchBloc extends Bloc<ProjectSearchEvent, ProjectSearchState> {
  final ProjectSearchRepository _repository;
  final AuthManager _authManager;
  final TagRepository _tagRepository;
  final OwnerRepository _ownerRepository;
  static final _logger = AppLogger().tag('ProjectSearchBloc');

  List<String> _cachedRecents = const [];
  List<String> _cachedSuggestions = const [];
  String _currentQuery = '';

  bool _suggestionsFetched = false;

  bool _suggestionsLoading = false;

  int _suggestionsFetchGeneration = 0;

  Set<String> _selectedTags = const {};

  // Full list of available tag names fetched from TagRepository.
  List<String> _availableTags = const [];

  // Whether _availableTags has been fetched at least once, so subsequent
  // sheet openings reuse the cached list instead of refetching.
  bool _availableTagsFetched = false;

  String _tagSearchQuery = '';

  Set<String> _selectedOwnerIds = const {};

  // Full list of available owners fetched from OwnerRepository.
  List<UserProfile> _availableOwners = const [];

  // Whether _availableOwners has been fetched at least once, so subsequent
  // sheet openings reuse the cached list instead of refetching.
  bool _availableOwnersFetched = false;

  String _ownerSearchQuery = '';

  DateRange? _selectedDateRange;

  /// Exposed for testing only — resolves when the last save-after-search
  /// completes, allowing tests to await it instead of using wall-clock waits.
  @visibleForTesting
  Future<void>? lastSaveCompleted;

  /// Creates a [ProjectSearchBloc] with the given [repository], [authManager],
  /// [tagRepository], and [ownerRepository].
  ProjectSearchBloc({
    required ProjectSearchRepository repository,
    required AuthManager authManager,
    required TagRepository tagRepository,
    required OwnerRepository ownerRepository,
  }) : _repository = repository,
       _authManager = authManager,
       _tagRepository = tagRepository,
       _ownerRepository = ownerRepository,
       super(const ProjectSearchInitial()) {
    on<ProjectSearchQueryUpdatedEvent>(
      (event, emit) => _handleQuery(event.query, emit),
      transformer: _debounce(_kQueryDebounceDuration),
    );
    on<ProjectSearchPerformedEvent>(_onPerformed);
    on<ProjectSearchHistoryRequestedEvent>(_onHistoryRequested);
    on<ProjectSearchHistoryItemDismissedEvent>(_onHistoryItemDismissed);
    on<ProjectSearchTagFiltersAppliedEvent>(_onTagFiltersApplied);
    on<ProjectSearchTagFilterClearedEvent>(_onTagFilterCleared);
    on<ProjectSearchAvailableTagsRequestedEvent>(
      _onAvailableTagsRequested,
      transformer: _restartable(),
    );
    // Intentionally not debounced: tag filtering is in-memory (no network
    // call), so instant per-keystroke feedback is cheap and preferable.
    on<ProjectSearchTagSearchQueryUpdatedEvent>(_onTagSearchQueryUpdated);
    on<ProjectSearchOwnerFiltersAppliedEvent>(_onOwnerFiltersApplied);
    on<ProjectSearchOwnerFilterClearedEvent>(_onOwnerFilterCleared);
    on<ProjectSearchAvailableOwnersRequestedEvent>(
      _onAvailableOwnersRequested,
      transformer: _restartable(),
    );
    // Intentionally not debounced: owner filtering is in-memory (no network
    // call), so instant per-keystroke feedback is cheap and preferable.
    on<ProjectSearchOwnerSearchQueryUpdatedEvent>(_onOwnerSearchQueryUpdated);
    on<ProjectSearchDateFilterAppliedEvent>(_onDateFilterApplied);
    on<ProjectSearchDateFilterClearedEvent>(_onDateFilterCleared);
  }

  Future<void> _handleQuery(
    String query,
    Emitter<ProjectSearchState> emit,
  ) async {
    _currentQuery = query;

    if (query.isEmpty) {
      // Clearing the field restores the history surface rather than blanking
      // it. It also cancels any same-pipeline suggestions fetch via the
      // switchMap transformer, so that handler can no longer emit its
      // completion — reset the flag here so this emission doesn't report a
      // loading fetch that will never complete visibly.
      _suggestionsLoading = false;
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

  Future<void> _fetchAndEmitSuggestions(
    Emitter<ProjectSearchState> emit,
  ) async {
    final userId = _authManager.getCurrentCredentials().data?.id;
    if (userId == null || userId.isEmpty) {
      _logger.warning('Suggestions fetch aborted: no authenticated user');
      emit(_initialFromCache());
      return;
    }

    final generation = ++_suggestionsFetchGeneration;
    _suggestionsLoading = true;
    emit(_initialFromCache());

    final result = await _repository.getProjectSearchSuggestions(
      userId: userId,
    );
    if (generation != _suggestionsFetchGeneration) return;
    _suggestionsLoading = false;
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
      // Preserve cached recents/suggestions instead of blanking the idle
      // surface, mirroring _handleQuery's empty-query branch.
      emit(_initialFromCache());
      return;
    }
    await _executeSearch(event.query, emit);
  }

  Future<void> _onHistoryRequested(
    ProjectSearchHistoryRequestedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    // Reset per-session suggestion and filter state — a fresh page open
    // re-fetches suggestions lazily on the user's first keystroke and starts
    // with no filters applied, matching Global Search's GlobalSearchStarted
    // behavior.
    _currentQuery = '';
    _cachedSuggestions = const [];
    _suggestionsFetched = false;
    _suggestionsLoading = false;
    // Disown any in-flight suggestions fetch: its completion must not
    // resurrect the pre-reset cache, mark suggestions as fetched, or emit
    // over the isLoadingHistory state emitted below.
    _suggestionsFetchGeneration++;
    _selectedTags = const {};
    _tagSearchQuery = '';
    _selectedOwnerIds = const {};
    _ownerSearchQuery = '';
    _selectedDateRange = null;

    final userId = _authManager.getCurrentCredentials().data?.id;
    if (userId == null || userId.isEmpty) {
      _logger.warning('History request aborted: no authenticated user');
      emit(const ProjectSearchInitial());
      return;
    }

    emit(
      ProjectSearchInitial(
        recentSearches: _cachedRecents,
        isLoadingHistory: true,
      ),
    );

    final result = await _repository.getRecentProjectSearches(userId: userId);

    // On failure, keep the previously cached value so a transient network
    // hiccup does not blank the history surface.
    _cachedRecents = result.fold<List<String>>((failure) {
      _logger.warning('Failed to load recent project searches: $failure');
      return _cachedRecents;
    }, (terms) => terms);

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

    result.fold((failure) {
      _logger.warning(
        'Failed to delete recent project search "${event.searchTerm}": $failure',
      );
    }, (_) => _removeDismissedTermAndEmit(event.searchTerm, emit));
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

    // The RPC accepts a single tag/owner, so a multi-selection is silently
    // truncated to the alphabetically-first value; log it until the RPC
    // supports multi-value filters.
    if (_selectedTags.length > 1) {
      _logger.warning(
        'Tag filter truncated: ${_selectedTags.length} tags selected, only '
        'the alphabetically-first is sent to the RPC',
      );
    }
    if (_selectedOwnerIds.length > 1) {
      _logger.warning(
        'Owner filter truncated: ${_selectedOwnerIds.length} owners selected, '
        'only the alphabetically-first is sent to the RPC',
      );
    }

    final result = await _repository.searchProjects(
      userId: userId,
      query: query,
      // The repository accepts a single tag; sort for deterministic selection
      // until the RPC is extended to support multi-tag filtering.
      filterByTag: _selectedTags.isEmpty
          ? null
          : (_selectedTags.toList()..sort()).first,
      // The repository accepts a single owner; sort for deterministic
      // selection until the RPC is extended to support multi-owner filtering.
      filterByOwner: _selectedOwnerIds.isEmpty
          ? null
          : (_selectedOwnerIds.toList()..sort()).first,
      // filter_by_date is a lower bound ("created on or after"); pass the
      // range start.
      filterByDate: _selectedDateRange?.start,
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
        final saveFuture = _saveSearchToHistory(
          userId: userId,
          query: query,
          hasResults: projects.isNotEmpty,
        );
        lastSaveCompleted = saveFuture;
        unawaited(saveFuture);
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

  // TODO: [CA-797] Track the loading flags as bloc instance fields consulted
  // here (like _availableTagsFetched) instead of caller-supplied parameters,
  // so a concurrently-handled event cannot reset an in-flight flag to false.
  // https://ripplearc.youtrack.cloud/issue/CA-797
  ProjectSearchInitial _initialFromCache({
    bool availableTagsLoading = false,
    bool availableOwnersLoading = false,
  }) => ProjectSearchInitial(
    recentSearches: _cachedRecents,
    suggestions: _filterSuggestions(_currentQuery),
    query: _currentQuery,
    suggestionsLoading: _suggestionsLoading,
    selectedTags: _selectedTags,
    availableTags: _filterAvailableTags(),
    availableTagsLoading: availableTagsLoading,
    selectedOwnerIds: _selectedOwnerIds,
    availableOwners: _filterAvailableOwners(),
    availableOwnersLoading: availableOwnersLoading,
    selectedDateRange: _selectedDateRange,
  );

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

  Future<void> _onAvailableTagsRequested(
    ProjectSearchAvailableTagsRequestedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    _tagSearchQuery = '';
    if (_availableTagsFetched) {
      emit(_initialFromCache());
      return;
    }

    emit(_initialFromCache(availableTagsLoading: true));

    final result = await _tagRepository.getTags();

    result.fold(
      (failure) {
        _logger.warning('Failed to load project search tags: $failure');
        emit(ProjectSearchTagsLoadFailure(failure: failure));
        emit(_initialFromCache());
      },
      (tags) {
        _availableTags = List.unmodifiable(tags.map((tag) => tag.name));
        _availableTagsFetched = true;
        emit(_initialFromCache());
      },
    );
  }

  void _onTagSearchQueryUpdated(
    ProjectSearchTagSearchQueryUpdatedEvent event,
    Emitter<ProjectSearchState> emit,
  ) {
    _tagSearchQuery = event.query.trim();
    emit(_initialFromCache());
  }

  void _onTagFiltersApplied(
    ProjectSearchTagFiltersAppliedEvent event,
    Emitter<ProjectSearchState> emit,
  ) {
    _selectedTags = Set.unmodifiable(event.tags);
    emit(_initialFromCache());
  }

  void _onTagFilterCleared(
    ProjectSearchTagFilterClearedEvent event,
    Emitter<ProjectSearchState> emit,
  ) {
    _selectedTags = Set.unmodifiable(
      _selectedTags.where((t) => t != event.tag),
    );
    emit(_initialFromCache());
  }

  Future<void> _onAvailableOwnersRequested(
    ProjectSearchAvailableOwnersRequestedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    _ownerSearchQuery = '';
    if (_availableOwnersFetched) {
      emit(_initialFromCache());
      return;
    }

    emit(_initialFromCache(availableOwnersLoading: true));

    final result = await _ownerRepository.getOwners();

    result.fold(
      (failure) {
        _logger.warning('Failed to load project search owners: $failure');
        emit(ProjectSearchOwnersLoadFailure(failure: failure));
        emit(_initialFromCache());
      },
      (owners) {
        _availableOwners = List.unmodifiable(owners);
        _availableOwnersFetched = true;
        emit(_initialFromCache());
      },
    );
  }

  void _onOwnerSearchQueryUpdated(
    ProjectSearchOwnerSearchQueryUpdatedEvent event,
    Emitter<ProjectSearchState> emit,
  ) {
    _ownerSearchQuery = event.query.trim();
    emit(_initialFromCache());
  }

  void _onOwnerFiltersApplied(
    ProjectSearchOwnerFiltersAppliedEvent event,
    Emitter<ProjectSearchState> emit,
  ) {
    _selectedOwnerIds = Set.unmodifiable(event.ownerIds);
    emit(_initialFromCache());
  }

  void _onOwnerFilterCleared(
    ProjectSearchOwnerFilterClearedEvent event,
    Emitter<ProjectSearchState> emit,
  ) {
    _selectedOwnerIds = Set.unmodifiable(
      _selectedOwnerIds.where((id) => id != event.ownerId),
    );
    emit(_initialFromCache());
  }

  void _onDateFilterApplied(
    ProjectSearchDateFilterAppliedEvent event,
    Emitter<ProjectSearchState> emit,
  ) {
    _selectedDateRange = event.range;
    emit(_initialFromCache());
  }

  void _onDateFilterCleared(
    ProjectSearchDateFilterClearedEvent event,
    Emitter<ProjectSearchState> emit,
  ) {
    _selectedDateRange = null;
    emit(_initialFromCache());
  }
}
