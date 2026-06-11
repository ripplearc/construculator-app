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

  const GlobalSearchReady({
    this.recentSearches = const [],
    this.query = '',
    this.suggestions = const [],
    this.suggestionsLoading = false,
    this.selectedTags = const {},
    this.availableTags = const [],
    this.availableTagsLoading = false,
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
  }) {
    return GlobalSearchReady(
      recentSearches: recentSearches ?? this.recentSearches,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      suggestionsLoading: suggestionsLoading ?? this.suggestionsLoading,
      selectedTags: selectedTags ?? this.selectedTags,
      availableTags: availableTags ?? this.availableTags,
      availableTagsLoading: availableTagsLoading ?? this.availableTagsLoading,
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

/// Emitted when a search returns at least one result.
class GlobalSearchLoadSuccess extends GlobalSearchState {
  /// The results returned by a successful search request.
  final SearchResults results;

  const GlobalSearchLoadSuccess({required this.results});

  @override
  List<Object?> get props => [results];
}

/// Emitted when a search completes successfully but returns no results.
class GlobalSearchLoadEmpty extends GlobalSearchState {
  /// The search query that produced no results.
  final String query;

  const GlobalSearchLoadEmpty({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Emitted when a search or history fetch fails.
class GlobalSearchLoadFailure extends GlobalSearchState {
  /// The failure describing why the search request failed.
  final Failure failure;

  const GlobalSearchLoadFailure({required this.failure});

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
class GlobalSearchRecentDeleteFailure extends GlobalSearchState {
  /// The failure describing why the recent search deletion failed.
  final Failure failure;

  const GlobalSearchRecentDeleteFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
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
