// coverage:ignore-file
part of 'global_search_bloc.dart';

/// Base sealed class for all GlobalSearch events
sealed class GlobalSearchEvent extends Equatable {
  const GlobalSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Event for initializing the search screen and loading recent search history
class GlobalSearchStarted extends GlobalSearchEvent {
  /// The scope to load recent searches for, defaults to [SearchScope.dashboard]
  final SearchScope scope;

  const GlobalSearchStarted({this.scope = SearchScope.dashboard});

  @override
  List<Object?> get props => [scope];
}

/// Event for updating the search query text field.
///
/// Can be dispatched on every keystroke — the BLoC applies a debounce
/// transformer so redundant rapid emissions are coalesced automatically.
class GlobalSearchQueryUpdated extends GlobalSearchEvent {
  /// The current value of the search input field
  final String query;

  const GlobalSearchQueryUpdated({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event for submitting a search query
class GlobalSearchPerformed extends GlobalSearchEvent {
  /// The search query entered by the user
  final String query;

  /// The scope to search within, defaults to [SearchScope.dashboard]
  final SearchScope scope;

  const GlobalSearchPerformed({
    required this.query,
    this.scope = SearchScope.dashboard,
  });

  @override
  List<Object?> get props => [query, scope];
}

/// Event for removing a term from the user's recent search history
class GlobalSearchRecentRemoved extends GlobalSearchEvent {
  /// The search term to remove
  final String searchTerm;

  /// The scope the search term belongs to
  final SearchScope scope;

  const GlobalSearchRecentRemoved({
    required this.searchTerm,
    required this.scope,
  });

  @override
  List<Object?> get props => [searchTerm, scope];
}

/// Event for loading personalized search suggestions
class GlobalSearchSuggestionsRequested extends GlobalSearchEvent {
  const GlobalSearchSuggestionsRequested();
}

/// Applies (or replaces) the active tag filter set.
///
/// Dispatched when the user taps Apply in the Tags filter sheet.
/// An empty [tags] set clears the tag filter entirely.
class GlobalSearchTagFiltersApplied extends GlobalSearchEvent {
  /// The set of tags to apply as active filters.
  final Set<String> tags;

  const GlobalSearchTagFiltersApplied({required this.tags});

  @override
  List<Object?> get props => [tags];
}

/// Clears a single tag from the active tag filter set.
///
/// Dispatched when the user taps the × icon on an individual active tag chip.
class GlobalSearchTagFilterCleared extends GlobalSearchEvent {
  /// The tag value to remove from the active filter set.
  final String tag;

  const GlobalSearchTagFilterCleared({required this.tag});

  @override
  List<Object?> get props => [tag];
}

/// Requests the list of available tags for the Tags filter sheet.
///
/// Dispatched when the user opens the Tags filter sheet. The BLoC fetches
/// tags from [TagRepository] on the first request and serves the cached
/// list on subsequent requests.
class GlobalSearchAvailableTagsRequested extends GlobalSearchEvent {
  const GlobalSearchAvailableTagsRequested();
}

/// Updates the search query used to filter the available tags list
/// inside the Tags filter sheet.
class GlobalSearchTagSearchQueryUpdated extends GlobalSearchEvent {
  /// The current value of the tag search input field.
  final String query;

  const GlobalSearchTagSearchQueryUpdated({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Applies (or replaces) the active owner filter set.
///
/// Dispatched when the user taps Apply in the Owner filter sheet.
/// An empty [ownerIds] set clears the owner filter entirely.
class GlobalSearchOwnerFiltersApplied extends GlobalSearchEvent {
  /// The set of owner ids to apply as active filters.
  final Set<String> ownerIds;

  const GlobalSearchOwnerFiltersApplied({required this.ownerIds});

  @override
  List<Object?> get props => [ownerIds];
}

/// Clears a single owner from the active owner filter set.
///
/// Dispatched when the user taps the × icon on an individual active owner chip.
class GlobalSearchOwnerFilterCleared extends GlobalSearchEvent {
  /// The owner id to remove from the active filter set.
  final String ownerId;

  const GlobalSearchOwnerFilterCleared({required this.ownerId});

  @override
  List<Object?> get props => [ownerId];
}

/// Requests the list of available owners for the Owner filter sheet.
///
/// Dispatched when the user opens the Owner filter sheet. The BLoC fetches
/// owners from [OwnerRepository] on the first request and serves the cached
/// list on subsequent requests.
class GlobalSearchAvailableOwnersRequested extends GlobalSearchEvent {
  const GlobalSearchAvailableOwnersRequested();
}

/// Updates the search query used to filter the available owners list
/// inside the Owner filter sheet.
class GlobalSearchOwnerSearchQueryUpdated extends GlobalSearchEvent {
  /// The current value of the owner search input field.
  final String query;

  const GlobalSearchOwnerSearchQueryUpdated({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Applies (or replaces) the active modification-date range filter.
///
/// Dispatched when the user taps Apply in [DateRangeBottomSheet].
class GlobalSearchDateFilterApplied extends GlobalSearchEvent {
  /// The date range to apply as the active filter.
  final DateRange range;

  const GlobalSearchDateFilterApplied({required this.range});

  @override
  List<Object?> get props => [range];
}

/// Clears the active modification-date range filter.
///
/// Dispatched when the user taps the × icon on the active date filter chip.
class GlobalSearchDateFilterCleared extends GlobalSearchEvent {
  const GlobalSearchDateFilterCleared();
}
