import 'package:construculator/features/global_search/data/models/search_params.dart';
import 'package:construculator/features/global_search/data/models/search_results_dto.dart';
import 'package:construculator/features/global_search/data/models/search_scope.dart';

/// Interface that abstracts global search data source operations.
///
/// This allows the global search feature to work with any backend implementation.
abstract class GlobalSearchDataSource {
  /// Performs a global search across projects, estimations, and members.
  ///
  /// [params] The search parameters including query, filters, and pagination.
  /// Returns [SearchResultsDto] with matching projects, estimations, and members.
  Future<SearchResultsDto> search(SearchParams params);

  /// Fetches recent search terms for the given [scope].
  ///
  /// Returns a list of search terms ordered by most recent first.
  /// Returns an empty list when the user is not authenticated.
  Future<List<String>> getRecentSearches(SearchScope scope);

  /// Saves a [searchTerm] for the given [scope] to recent searches.
  ///
  /// Normalizes the term to lowercase and trims whitespace.
  /// [projectId] is the project context in which the search was performed.
  /// It is nullable for searches not scoped to a specific project (e.g. dashboard).
  /// [hasResults] should be true only when the search returned at least one result.
  /// Terms with [hasResults] = false are saved to history but excluded from suggestions.
  /// Does nothing when the user is not authenticated or the term is empty.
  Future<void> saveRecentSearch(
    String searchTerm,
    SearchScope scope, {
    String? projectId,
    bool hasResults = false,
  });

  /// Removes a [searchTerm] from recent searches for the given [scope].
  ///
  /// Does NOT affect search_analytics — global suggestion counts are preserved.
  /// Does nothing when the user is not authenticated or the term is empty.
  Future<void> deleteRecentSearch(String searchTerm, SearchScope scope);

  /// Fetches personalized search suggestions for the authenticated user.
  ///
  /// Priority 1: user's own search history (has_results = true), sorted by frequency.
  /// Priority 2: searches by teammates within shared projects (has_results = true).
  /// Returns an empty list when no suggestions are found or the user is not authenticated.
  Future<List<String>> getSearchSuggestions();
}
