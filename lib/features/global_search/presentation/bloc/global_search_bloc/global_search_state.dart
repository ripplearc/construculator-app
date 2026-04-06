// coverage:ignore-file
part of 'global_search_bloc.dart';

/// Base sealed class for all GlobalSearch states.
sealed class GlobalSearchState extends Equatable {
  const GlobalSearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state shown before or between searches.
///
/// Holds the user's [recentSearches], the current [query] text, and optional
/// [suggestions] when loaded via [GlobalSearchSuggestionsRequested].
class GlobalSearchInitial extends GlobalSearchState {
  final List<String> recentSearches;
  final String query;
  final List<String> suggestions;
  final bool suggestionsLoading;

  const GlobalSearchInitial({
    this.recentSearches = const [],
    this.query = '',
    this.suggestions = const [],
    this.suggestionsLoading = false,
  });

  GlobalSearchInitial copyWith({
    List<String>? recentSearches,
    String? query,
    List<String>? suggestions,
    bool? suggestionsLoading,
  }) {
    return GlobalSearchInitial(
      recentSearches: recentSearches ?? this.recentSearches,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      suggestionsLoading: suggestionsLoading ?? this.suggestionsLoading,
    );
  }

  @override
  List<Object?> get props => [recentSearches, query, suggestions, suggestionsLoading];
}

/// Emitted while a search request is in flight.
class GlobalSearchLoadInProgress extends GlobalSearchState {
  final String query;

  const GlobalSearchLoadInProgress({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Emitted when a search returns at least one result.
class GlobalSearchLoadSuccess extends GlobalSearchState {
  final SearchResults results;

  const GlobalSearchLoadSuccess({required this.results});

  @override
  List<Object?> get props => [results];
}

/// Emitted when a search completes successfully but returns no results.
class GlobalSearchLoadEmpty extends GlobalSearchState {
  final String query;

  const GlobalSearchLoadEmpty({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Emitted when a search or history fetch fails.
class GlobalSearchLoadFailure extends GlobalSearchState {
  final Failure failure;

  const GlobalSearchLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Emitted when loading personalized suggestions fails.
class GlobalSearchSuggestionsLoadFailure extends GlobalSearchState {
  final Failure failure;

  const GlobalSearchSuggestionsLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// Emitted when removing a recent search term from history fails.
class GlobalSearchRecentDeleteFailure extends GlobalSearchState {
  final Failure failure;

  const GlobalSearchRecentDeleteFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
