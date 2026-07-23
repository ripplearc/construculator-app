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

/// Dispatched when the user taps Apply in the Tags filter sheet.
class ProjectSearchTagFiltersAppliedEvent extends ProjectSearchEvent {
  /// The tags selected in the sheet at the time Apply was tapped.
  final Set<String> tags;

  /// Creates a [ProjectSearchTagFiltersAppliedEvent] with the given [tags].
  const ProjectSearchTagFiltersAppliedEvent({required this.tags});

  @override
  List<Object?> get props => [tags];
}

/// Dispatched when the user clears a single active tag filter chip.
class ProjectSearchTagFilterClearedEvent extends ProjectSearchEvent {
  /// The tag to remove from the active filter set.
  final String tag;

  /// Creates a [ProjectSearchTagFilterClearedEvent] with the given [tag].
  const ProjectSearchTagFilterClearedEvent({required this.tag});

  @override
  List<Object?> get props => [tag];
}

/// Requests the list of available tags for the Tags filter sheet.
///
/// Dispatched when the user opens the Tags filter sheet. The BLoC fetches
/// tags from `TagRepository` on the first request and serves the cached list
/// on subsequent openings.
class ProjectSearchAvailableTagsRequestedEvent extends ProjectSearchEvent {
  /// Creates a [ProjectSearchAvailableTagsRequestedEvent].
  const ProjectSearchAvailableTagsRequestedEvent();
}

/// Dispatched as the user types in the tag search field inside the Tags
/// filter sheet.
class ProjectSearchTagSearchQueryUpdatedEvent extends ProjectSearchEvent {
  /// The current value of the tag search field.
  final String query;

  /// Creates a [ProjectSearchTagSearchQueryUpdatedEvent] with the given [query].
  const ProjectSearchTagSearchQueryUpdatedEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Dispatched when the user taps Apply in the Owner filter sheet.
class ProjectSearchOwnerFiltersAppliedEvent extends ProjectSearchEvent {
  /// The owner ids selected in the sheet at the time Apply was tapped.
  final Set<String> ownerIds;

  /// Creates a [ProjectSearchOwnerFiltersAppliedEvent] with the given [ownerIds].
  const ProjectSearchOwnerFiltersAppliedEvent({required this.ownerIds});

  @override
  List<Object?> get props => [ownerIds];
}

/// Dispatched when the user clears a single active owner filter chip.
class ProjectSearchOwnerFilterClearedEvent extends ProjectSearchEvent {
  /// The owner id to remove from the active filter set.
  final String ownerId;

  /// Creates a [ProjectSearchOwnerFilterClearedEvent] with the given [ownerId].
  const ProjectSearchOwnerFilterClearedEvent({required this.ownerId});

  @override
  List<Object?> get props => [ownerId];
}

/// Requests the list of available owners for the Owner filter sheet.
///
/// Dispatched when the user opens the Owner filter sheet. The BLoC fetches
/// owners from `OwnerRepository` on the first request and serves the cached
/// list on subsequent openings.
class ProjectSearchAvailableOwnersRequestedEvent extends ProjectSearchEvent {
  /// Creates a [ProjectSearchAvailableOwnersRequestedEvent].
  const ProjectSearchAvailableOwnersRequestedEvent();
}

/// Dispatched as the user types in the owner search field inside the Owner
/// filter sheet.
class ProjectSearchOwnerSearchQueryUpdatedEvent extends ProjectSearchEvent {
  /// The current value of the owner search field.
  final String query;

  /// Creates a [ProjectSearchOwnerSearchQueryUpdatedEvent] with the given [query].
  const ProjectSearchOwnerSearchQueryUpdatedEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Dispatched when the user taps Apply in [CoreDateRangeSheet].
class ProjectSearchDateFilterAppliedEvent extends ProjectSearchEvent {
  /// The modification-date range selected by the user.
  final DateRange range;

  /// Creates a [ProjectSearchDateFilterAppliedEvent] with the given [range].
  const ProjectSearchDateFilterAppliedEvent({required this.range});

  @override
  List<Object?> get props => [range];
}

/// Dispatched when the user clears the active modification-date filter.
class ProjectSearchDateFilterClearedEvent extends ProjectSearchEvent {
  /// Creates a [ProjectSearchDateFilterClearedEvent].
  const ProjectSearchDateFilterClearedEvent();
}
