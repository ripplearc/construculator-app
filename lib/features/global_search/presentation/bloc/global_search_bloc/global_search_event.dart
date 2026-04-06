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

/// Event for updating the search query text field
///
/// The UI must debounce before dispatching this event to avoid emitting on every keystroke
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
