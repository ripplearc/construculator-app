// coverage:ignore-file
part of 'global_search_bloc.dart';

/// Base sealed class for all GlobalSearch events.
sealed class GlobalSearchEvent extends Equatable {
  const GlobalSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the search screen is first opened or re-initialized.
///
/// Triggers loading of the authenticated user's recent search history for the
/// given [scope]. Defaults to [SearchScope.dashboard] so existing call sites
/// that open the global search from the dashboard require no change.
class GlobalSearchStarted extends GlobalSearchEvent {
  final SearchScope scope;

  const GlobalSearchStarted({this.scope = SearchScope.dashboard});

  @override
  List<Object?> get props => [scope];
}

/// Fired when the user edits the text in the search input field.
///
/// The handler is purely synchronous — no use case is invoked and no network
/// call is made. The [query] is reflected in the emitted state so the UI text
/// field stays in sync.
///
/// **Debouncing responsibility:** This event MUST be dispatched by the UI only
/// after applying a debounce (e.g. a 300 ms `Timer` or `rxdart` debounceTime)
/// before the call site. The BLoC itself does not debounce to keep event
/// handling simple and testable.
class GlobalSearchQueryUpdated extends GlobalSearchEvent {
  final String query;

  const GlobalSearchQueryUpdated({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Fired when the user submits a search (e.g. presses the keyboard Search action).
///
/// Triggers a full search across projects, estimations, and members via
/// [PerformSearchUseCase] using the supplied [scope]. The [scope] is also
/// forwarded to [SaveRecentSearchUseCase] so the history record is scoped
/// correctly. Defaults to [SearchScope.dashboard].
class GlobalSearchPerformed extends GlobalSearchEvent {
  final String query;
  final SearchScope scope;

  const GlobalSearchPerformed({
    required this.query,
    this.scope = SearchScope.dashboard,
  });

  @override
  List<Object?> get props => [query, scope];
}

/// Fired when the user removes a term from their recent search history.
///
/// Deletes the term for the given [searchTerm] and [scope].
class GlobalSearchRecentRemoved extends GlobalSearchEvent {
  final String searchTerm;
  final SearchScope scope;

  const GlobalSearchRecentRemoved({
    required this.searchTerm,
    required this.scope,
  });

  @override
  List<Object?> get props => [searchTerm, scope];
}

/// Fired when the UI should load personalized search suggestions
/// (e.g. on field focus or debounced input).
class GlobalSearchSuggestionsRequested extends GlobalSearchEvent {
  const GlobalSearchSuggestionsRequested();
}
