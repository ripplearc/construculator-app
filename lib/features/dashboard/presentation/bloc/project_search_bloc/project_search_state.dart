// coverage:ignore-file
part of 'project_search_bloc.dart';

/// Base sealed class for all [ProjectSearchBloc] states.
sealed class ProjectSearchState extends Equatable {
  /// Creates a [ProjectSearchState].
  const ProjectSearchState();

  @override
  List<Object?> get props => [];
}

/// Cold start before any search has been performed.
class ProjectSearchInitial extends ProjectSearchState {
  /// Creates a [ProjectSearchInitial].
  const ProjectSearchInitial();
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
