import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';

/// Abstract repository contract for project-scoped search.
///
/// Returns [Either] so callers receive a typed [Failure] on error rather than
/// catching exceptions directly.
abstract class ProjectSearchRepository {
  /// Searches projects accessible to [userId] that match [query].
  ///
  /// Optional filters:
  /// - [filterByDate]: only projects created on or after this date.
  /// - [filterByTag]: only projects tagged with this value.
  /// - [filterByOwner]: only projects owned by this user id.
  ///
  /// Returns an empty list when [query] or [userId] is empty.
  Future<Either<Failure, List<Project>>> searchProjects({
    required String userId,
    required String query,
    DateTime? filterByDate,
    String? filterByTag,
    String? filterByOwner,
  });

  /// Persists [searchTerm] as a recent project-search entry for [userId].
  ///
  /// [hasResults] should be `true` only when the caller has confirmed the
  /// search returned at least one result. Repeat saves of the same term are
  /// de-duplicated rather than creating multiple entries.
  ///
  /// Returns `Right` (void) when [userId] is empty or [searchTerm] is
  /// empty/whitespace — no failure is raised for these inputs.
  Future<Either<Failure, void>> saveRecentProjectSearch({
    required String userId,
    required String searchTerm,
    bool hasResults = false,
  });

  /// Returns [userId]'s recent project-search terms, most recently used first.
  ///
  /// Returns `Right([])` when [userId] is empty.
  Future<Either<Failure, List<String>>> getRecentProjectSearches({
    required String userId,
  });

  /// Removes [searchTerm] from [userId]'s recent project-search history.
  ///
  /// Returns `Right` (void) when [userId] is empty or [searchTerm] is
  /// empty/whitespace.
  Future<Either<Failure, void>> deleteRecentProjectSearch({
    required String userId,
    required String searchTerm,
  });

  /// Returns up to 10 personalized project-search suggestion terms for [userId].
  ///
  /// Returns `Right([])` when [userId] is empty or no suggestions exist.
  Future<Either<Failure, List<String>>> getProjectSearchSuggestions({
    required String userId,
  });
}
