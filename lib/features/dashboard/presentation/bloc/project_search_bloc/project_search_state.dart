// coverage:ignore-file
part of 'project_search_bloc.dart';

/// Base sealed class for all [ProjectSearchBloc] states.
sealed class ProjectSearchState extends Equatable {
  /// Creates a [ProjectSearchState].
  const ProjectSearchState();

  @override
  List<Object?> get props => [];
}

/// Idle / cold-start state shown when no active search is in flight.
///
/// Carries the user's [recentSearches] and personalized [suggestions] so the
/// UI can render both surfaces from a single state. [isLoadingHistory] is
/// `true` while the parallel fetch of recents + suggestions is in flight.
/// [query] holds the current (debounced) search-field value — typing filters
/// [suggestions] in place rather than triggering a live remote search;
/// [ProjectSearchPerformedEvent] is what runs the actual search.
/// [suggestionsLoading] is `true` while the first suggestions fetch for a
/// non-empty query is in flight.
class ProjectSearchInitial extends ProjectSearchState {
  /// The user's recent project-search terms, most recently used first.
  final List<String> recentSearches;

  /// Personalized project-search suggestion terms, filtered by [query].
  final List<String> suggestions;

  /// `true` while recents and suggestions are being fetched.
  final bool isLoadingHistory;

  /// The current value of the search input field.
  final String query;

  /// `true` while the first suggestions fetch for a non-empty query is in
  /// flight.
  final bool suggestionsLoading;

  /// Tags currently applied as filters. Empty means no tag filter is active.
  final Set<String> selectedTags;

  /// Available tag names to display in the Tags filter sheet, already
  /// filtered by the current tag search query.
  final List<String> availableTags;

  /// `true` while the available tags fetch is currently in flight.
  final bool availableTagsLoading;

  /// Owner ids currently applied as filters. Empty means no owner filter is
  /// active.
  final Set<String> selectedOwnerIds;

  /// Available owners to display in the Owner filter sheet, already filtered
  /// by the current owner search query.
  final List<UserProfile> availableOwners;

  /// `true` while the available owners fetch is currently in flight.
  final bool availableOwnersLoading;

  /// The modification-date range currently applied as a filter, if any.
  final DateRange? selectedDateRange;

  /// Creates a [ProjectSearchInitial] with the given [recentSearches],
  /// [suggestions], [isLoadingHistory], [query], [suggestionsLoading], and the
  /// active/available filter fields.
  const ProjectSearchInitial({
    this.recentSearches = const [],
    this.suggestions = const [],
    this.isLoadingHistory = false,
    this.query = '',
    this.suggestionsLoading = false,
    this.selectedTags = const {},
    this.availableTags = const [],
    this.availableTagsLoading = false,
    this.selectedOwnerIds = const {},
    this.availableOwners = const [],
    this.availableOwnersLoading = false,
    this.selectedDateRange,
  });

  @override
  List<Object?> get props => [
    recentSearches,
    suggestions,
    isLoadingHistory,
    query,
    suggestionsLoading,
    selectedTags,
    availableTags,
    availableTagsLoading,
    selectedOwnerIds,
    availableOwners,
    availableOwnersLoading,
    selectedDateRange,
  ];
}

/// Emitted while a search request is in flight.
class ProjectSearchLoading extends ProjectSearchState {
  /// The search query that triggered this in-progress request.
  final String query;

  /// Creates a [ProjectSearchLoading] with the given [query].
  const ProjectSearchLoading({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Emitted when a search completes — [results] may be empty.
///
/// Carries [query] alongside [results] so the UI can display the current
/// search term without needing additional state.
class ProjectSearchResultsLoaded extends ProjectSearchState {
  /// The projects returned by the search. May be empty.
  final List<Project> results;

  /// The query that produced these results.
  final String query;

  /// Creates a [ProjectSearchResultsLoaded] with the given [results] and [query].
  const ProjectSearchResultsLoaded({
    required this.results,
    required this.query,
  });

  @override
  List<Object?> get props => [results, query];
}

/// Emitted when a search fails.
class ProjectSearchFailureState extends ProjectSearchState {
  /// The failure describing why the search failed.
  final Failure failure;

  /// The query that was being searched when the failure occurred.
  final String query;

  /// Creates a [ProjectSearchFailureState] with the given [failure] and [query].
  const ProjectSearchFailureState({required this.failure, required this.query});

  @override
  List<Object?> get props => [failure, query];
}

/// Emitted when loading the available tags for the filter sheet fails.
///
/// Transient: the BLoC re-emits a [ProjectSearchInitial] immediately after so
/// the idle surface (with its cached filter state) remains interactive.
class ProjectSearchTagsLoadFailure extends ProjectSearchState {
  /// The failure describing why the tags fetch failed.
  final Failure failure;

  /// Creates a [ProjectSearchTagsLoadFailure] with the given [failure].
  const ProjectSearchTagsLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Emitted when loading the available owners for the filter sheet fails.
///
/// Transient: the BLoC re-emits a [ProjectSearchInitial] immediately after so
/// the idle surface (with its cached filter state) remains interactive.
class ProjectSearchOwnersLoadFailure extends ProjectSearchState {
  /// The failure describing why the owners fetch failed.
  final Failure failure;

  /// Creates a [ProjectSearchOwnersLoadFailure] with the given [failure].
  const ProjectSearchOwnersLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Emitted when deleting a recent search term from history fails.
///
/// Transient: the BLoC re-emits a [ProjectSearchInitial] immediately after,
/// so the history surface stays interactive while the toast surfaces the
/// failure and the term's row resolves its pending swipe by [searchTerm].
class ProjectSearchHistoryDeleteFailure extends ProjectSearchState {
  /// The failure describing why the history deletion failed.
  final Failure failure;

  /// The term whose deletion failed, echoed verbatim from the event so the
  /// row that requested it — and only that row — can resolve its swipe.
  final String searchTerm;

  /// Creates a [ProjectSearchHistoryDeleteFailure] with the given [failure]
  /// and [searchTerm].
  const ProjectSearchHistoryDeleteFailure({
    required this.failure,
    required this.searchTerm,
  });

  @override
  List<Object?> get props => [failure, searchTerm];
}

/// Emitted when a recent search term is deleted from history.
///
/// Transient: the BLoC re-emits a [ProjectSearchInitial] — already without
/// the term — immediately after. Carries [searchTerm] so the row that
/// requested the deletion, and only that row, completes its swipe dismissal.
class ProjectSearchHistoryDeleteSuccess extends ProjectSearchState {
  /// The deleted term, echoed verbatim from the event.
  final String searchTerm;

  /// Creates a [ProjectSearchHistoryDeleteSuccess] with the given
  /// [searchTerm].
  const ProjectSearchHistoryDeleteSuccess({required this.searchTerm});

  @override
  List<Object?> get props => [searchTerm];
}
