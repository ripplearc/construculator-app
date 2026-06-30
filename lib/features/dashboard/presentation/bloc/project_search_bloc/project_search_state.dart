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

  /// Creates a [ProjectSearchInitial] with the given [recentSearches],
  /// [suggestions], [isLoadingHistory], [query], and [suggestionsLoading].
  const ProjectSearchInitial({
    this.recentSearches = const [],
    this.suggestions = const [],
    this.isLoadingHistory = false,
    this.query = '',
    this.suggestionsLoading = false,
  });

  @override
  List<Object?> get props => [
    recentSearches,
    suggestions,
    isLoadingHistory,
    query,
    suggestionsLoading,
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
  const ProjectSearchResultsLoaded({required this.results, required this.query});

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
