import 'package:construculator/features/global_search/data/models/search_params.dart';
import 'package:construculator/features/global_search/data/models/search_scope.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Abstract repository interface for global search operations.
///
/// This repository defines the contract for searching across projects,
/// cost estimations, and members, as well as managing per-user search history
/// and suggestions. It follows the repository pattern to decouple the domain
/// layer from the specific data source implementation.
///
/// All methods return [Either] so that callers receive a typed [Failure] on
/// error rather than catching exceptions directly.
abstract class GlobalSearchRepository {
  /// Performs a global search using the supplied [params].
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or a [SearchResults] holding matched projects, estimations,
  /// and members.
  ///
  /// Filtering (tag, date, owner, scope) and pagination are driven by [params].
  Future<Either<Failure, SearchResults>> search(SearchParams params);

  /// Fetches the authenticated user's recent search terms for the given [scope].
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or a [List<String>] ordered by most recent first.
  /// Returns an empty list when the user is not authenticated.
  Future<Either<Failure, List<String>>> getRecentSearches(SearchScope scope);

  /// Saves [searchTerm] to the authenticated user's history for [scope].
  ///
  /// [projectId] is the project context in which the search was performed.
  /// It is nullable for searches not scoped to a specific project (e.g. dashboard).
  /// [hasResults] should be `true` only when the search returned at least one result.
  /// Terms saved with [hasResults] = false are kept in history but excluded from
  /// suggestions.
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or void on success.
  /// Does nothing when the user is not authenticated or the term is empty.
  Future<Either<Failure, void>> saveRecentSearch(
    String searchTerm,
    SearchScope scope, {
    String? projectId,
    bool hasResults = false,
  });

  /// Removes [searchTerm] from the authenticated user's history for [scope].
  ///
  /// Does NOT affect global suggestion counts — the term's analytics record is
  /// preserved.
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or void on success.
  /// Does nothing when the user is not authenticated or the term is empty.
  Future<Either<Failure, void>> deleteRecentSearch(
    String searchTerm,
    SearchScope scope,
  );

  /// Fetches personalized search suggestions for the authenticated user.
  ///
  /// Priority 1: user's own search history (has_results = true), sorted by
  /// frequency.
  /// Priority 2: searches by teammates within shared projects (has_results = true).
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or a [List<String>].
  /// Returns an empty list when no suggestions are found or the user is not
  /// authenticated.
  Future<Either<Failure, List<String>>> getSearchSuggestions();
}
