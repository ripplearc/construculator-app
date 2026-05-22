// coverage:ignore-file
part of 'project_search_bloc.dart';

/// Base sealed class for all [ProjectSearchBloc] events.
sealed class ProjectSearchEvent extends Equatable {
  /// Creates a [ProjectSearchEvent].
  const ProjectSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched on every keystroke — the BLoC applies a debounce transformer
/// so rapid emissions are coalesced automatically before triggering a search.
class ProjectSearchQueryUpdatedEvent extends ProjectSearchEvent {
  /// The current value of the search input field.
  final String query;

  /// Creates a [ProjectSearchQueryUpdatedEvent] with the given [query].
  const ProjectSearchQueryUpdatedEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Dispatched when the user explicitly submits a search (e.g. tap or enter).
///
/// Unlike [ProjectSearchQueryUpdatedEvent], this is not debounced and triggers
/// an immediate search.
class ProjectSearchPerformedEvent extends ProjectSearchEvent {
  /// The search query submitted by the user.
  final String query;

  /// Creates a [ProjectSearchPerformedEvent] with the given [query].
  const ProjectSearchPerformedEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Dispatched when the project-search surface opens to request recent searches
/// and personalized suggestions in parallel.
class ProjectSearchHistoryRequestedEvent extends ProjectSearchEvent {
  /// Creates a [ProjectSearchHistoryRequestedEvent].
  const ProjectSearchHistoryRequestedEvent();
}

/// Dispatched when the user dismisses a single recent-search chip.
class ProjectSearchHistoryItemDismissedEvent extends ProjectSearchEvent {
  /// The recent-search term to remove from history.
  final String searchTerm;

  /// Creates a [ProjectSearchHistoryItemDismissedEvent] with the given
  /// [searchTerm].
  const ProjectSearchHistoryItemDismissedEvent({required this.searchTerm});

  @override
  List<Object?> get props => [searchTerm];
}
