// coverage:ignore-file
part of 'global_search_bloc.dart';

/// Base sealed class for all GlobalSearch states.
sealed class GlobalSearchState extends Equatable {
  const GlobalSearchState();

  @override
  List<Object?> get props => [];
}

/// Cold start before [GlobalSearchStarted] has completed (no history loaded yet).
class GlobalSearchInitial extends GlobalSearchState {
  const GlobalSearchInitial();
}

/// Idle / interactive state after history has been loaded at least once.
///
/// Emitted after [GlobalSearchStarted], on [GlobalSearchQueryUpdated], while
/// loading suggestions, and after history or suggestions change.
class GlobalSearchReady extends GlobalSearchState {
  /// Recent search terms previously submitted by the user.
  final List<String> recentSearches;

  /// The current text typed into the search field.
  final String query;

  /// Personalized search suggestions fetched from the repository.
  final List<String> suggestions;

  /// Whether a suggestions fetch is currently in flight.
  final bool suggestionsLoading;

  /// Tags currently applied as filters. Empty means no tag filter is active.
  final Set<String> selectedTags;

  /// Available tag names to display in the Tags filter sheet, already
  /// filtered by the current tag search query.
  final List<String> availableTags;

  /// Whether the available tags fetch is currently in flight.
  final bool availableTagsLoading;

  /// Owner ids currently applied as filters. Empty means no owner filter
  /// is active.
  final Set<String> selectedOwnerIds;

  /// Available owners to display in the Owner filter sheet, already filtered
  /// by the current owner search query.
  final List<UserProfile> availableOwners;

  /// Whether the available owners fetch is currently in flight.
  final bool availableOwnersLoading;

  /// The modification-date range currently applied as a filter, if any.
  final DateRange? selectedDateRange;

  /// The scope (Type filter) the search currently operates within.
  /// [SearchScope.dashboard] means all domains and renders as no active
  /// Type filter.
  final SearchScope selectedScope;

  /// The scope the displayed [recentSearches] belong to. Lags behind
  /// [selectedScope] while a scope change's history reload is in flight,
  /// so a deletion swiped in that window targets the history actually on
  /// screen rather than the newly selected scope's.
  final SearchScope recentsScope;

  const GlobalSearchReady({
    this.recentSearches = const [],
    this.query = '',
    this.suggestions = const [],
    this.suggestionsLoading = false,
    this.selectedTags = const {},
    this.availableTags = const [],
    this.availableTagsLoading = false,
    this.selectedOwnerIds = const {},
    this.availableOwners = const [],
    this.availableOwnersLoading = false,
    this.selectedDateRange,
    this.selectedScope = SearchScope.dashboard,
    this.recentsScope = SearchScope.dashboard,
  });

  /// Returns a copy of this state with the given fields replaced.
  GlobalSearchReady copyWith({
    List<String>? recentSearches,
    String? query,
    List<String>? suggestions,
    bool? suggestionsLoading,
    Set<String>? selectedTags,
    List<String>? availableTags,
    bool? availableTagsLoading,
    Set<String>? selectedOwnerIds,
    List<UserProfile>? availableOwners,
    bool? availableOwnersLoading,
    DateRange? selectedDateRange,
    SearchScope? selectedScope,
    SearchScope? recentsScope,
  }) {
    return GlobalSearchReady(
      recentSearches: recentSearches ?? this.recentSearches,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      suggestionsLoading: suggestionsLoading ?? this.suggestionsLoading,
      selectedTags: selectedTags ?? this.selectedTags,
      availableTags: availableTags ?? this.availableTags,
      availableTagsLoading: availableTagsLoading ?? this.availableTagsLoading,
      selectedOwnerIds: selectedOwnerIds ?? this.selectedOwnerIds,
      availableOwners: availableOwners ?? this.availableOwners,
      availableOwnersLoading:
          availableOwnersLoading ?? this.availableOwnersLoading,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      selectedScope: selectedScope ?? this.selectedScope,
      recentsScope: recentsScope ?? this.recentsScope,
    );
  }

  @override
  List<Object?> get props => [
    recentSearches,
    query,
    suggestions,
    suggestionsLoading,
    selectedTags,
    availableTags,
    availableTagsLoading,
    selectedOwnerIds,
    availableOwners,
    availableOwnersLoading,
    selectedDateRange,
    selectedScope,
    recentsScope,
  ];
}

/// Emitted while a search request is in flight.
class GlobalSearchLoadInProgress extends GlobalSearchState {
  /// The search query that triggered this in-progress request.
  final String query;

  const GlobalSearchLoadInProgress({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Progress of a load-more (next results page) request on the results surface.
enum GlobalSearchLoadMoreStatus {
  /// No page fetch is in flight; the list may request the next page.
  idle,

  /// A page fetch is in flight; the list shows a loading footer.
  inProgress,

  /// The last page fetch failed; the list shows a retry footer while the
  /// already-loaded results stay visible.
  failure,
}

/// Emitted when a search returns at least one result.
class GlobalSearchLoadSuccess extends GlobalSearchState {
  /// The results returned by a successful search request, accumulated across
  /// all pages loaded so far for the active query.
  final SearchResults results;

  /// Whether more estimation results may exist beyond the loaded pages.
  ///
  /// Derived from the last page's size versus the request limit. Estimations
  /// are the only paginated domain until CA-979 splits the per-domain offsets.
  /// https://ripplearc.youtrack.cloud/issue/CA-979
  final bool hasMoreEstimations;

  /// Progress of the in-flight or last load-more request.
  final GlobalSearchLoadMoreStatus loadMoreStatus;

  const GlobalSearchLoadSuccess({
    required this.results,
    this.hasMoreEstimations = false,
    this.loadMoreStatus = GlobalSearchLoadMoreStatus.idle,
  });

  @override
  List<Object?> get props => [results, hasMoreEstimations, loadMoreStatus];
}

/// Emitted when a search completes successfully but returns no results.
class GlobalSearchLoadEmpty extends GlobalSearchState {
  /// The search query that produced no results.
  final String query;

  const GlobalSearchLoadEmpty({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Emitted when a performed search fails.
class GlobalSearchLoadFailure extends GlobalSearchState {
  /// The failure describing why the search request failed.
  final Failure failure;

  /// The query that was being searched when the failure occurred; used by
  /// the retry affordance to re-run the failed search.
  final String query;

  const GlobalSearchLoadFailure({required this.failure, required this.query});

  @override
  List<Object?> get props => [failure, query];
}

/// Emitted when fetching the recent-search history fails.
class GlobalSearchRecentsLoadFailure extends GlobalSearchState {
  /// The failure describing why the history fetch failed.
  final Failure failure;

  const GlobalSearchRecentsLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Emitted when loading personalized suggestions fails.
class GlobalSearchSuggestionsLoadFailure extends GlobalSearchState {
  /// The failure describing why the suggestions fetch failed.
  final Failure failure;

  const GlobalSearchSuggestionsLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Emitted when [GlobalSearchPerformed] is dispatched with an empty or
/// whitespace-only query so the UI can surface a validation message.
class GlobalSearchEmptyQuery extends GlobalSearchState {
  /// Creates a [GlobalSearchEmptyQuery] state.
  const GlobalSearchEmptyQuery();

  @override
  List<Object?> get props => const [];
}

/// Emitted when removing a recent search term from history fails.
///
/// Transient: the BLoC re-emits the ready state immediately after, so the
/// idle surface stays interactive while the toast surfaces the failure and
/// the term's row resolves its pending swipe by [searchTerm].
class GlobalSearchRecentDeleteFailure extends GlobalSearchState {
  /// The failure describing why the recent search deletion failed.
  final Failure failure;

  /// The term whose deletion failed, echoed verbatim from the event so the
  /// row that requested it — and only that row — can resolve its swipe.
  final String searchTerm;

  const GlobalSearchRecentDeleteFailure({
    required this.failure,
    required this.searchTerm,
  });

  @override
  List<Object?> get props => [failure, searchTerm];
}

/// Emitted when a recent search term is deleted from history.
///
/// Transient: the BLoC re-emits the ready state — already without the term —
/// immediately after. Carries [searchTerm] so the row that requested the
/// deletion, and only that row, completes its swipe dismissal.
class GlobalSearchRecentDeleteSuccess extends GlobalSearchState {
  /// The deleted term, echoed verbatim from the event.
  final String searchTerm;

  const GlobalSearchRecentDeleteSuccess({required this.searchTerm});

  @override
  List<Object?> get props => [searchTerm];
}

/// Emitted when loading the available tags for the filter sheet fails.
class GlobalSearchTagsLoadFailure extends GlobalSearchState {
  /// The failure describing why the tags fetch failed.
  final Failure failure;

  /// Creates a [GlobalSearchTagsLoadFailure].
  const GlobalSearchTagsLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Emitted when loading the available owners for the filter sheet fails.
class GlobalSearchOwnersLoadFailure extends GlobalSearchState {
  /// The failure describing why the owners fetch failed.
  final Failure failure;

  /// Creates a [GlobalSearchOwnersLoadFailure].
  const GlobalSearchOwnersLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}