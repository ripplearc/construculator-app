import 'package:construculator/libraries/project/data/models/project_dto.dart';

/// Interface that abstracts project search data source operations.
///
/// Implementations must rethrow all exceptions — error mapping is the
/// repository's responsibility.
abstract class ProjectSearchDataSource {
  /// Searches projects matching [query] for the given [userId].
  ///
  /// Returns an empty list when [query] or [userId] is empty without calling
  /// the remote API. [userId] may be used as an early-exit guard; backend user
  /// scoping is implementation-specific and not required to be forwarded as an
  /// explicit parameter.
  Future<List<ProjectDto>> fetchProjectsBySearchQuery({
    required String userId,
    required String query,
    DateTime? filterByDate,
    String? filterByTag,
    String? filterByOwner,
  });

  /// Persists [searchTerm] as a recent project-search entry for [userId].
  ///
  /// [hasResults] should be `true` only when the caller has confirmed the
  /// search returned at least one result. Repeat saves of the same term
  /// increment the per-term count rather than producing duplicates.
  ///
  /// Does nothing when [userId] is empty or [searchTerm] is empty/whitespace.
  Future<void> saveRecentProjectSearch({
    required String userId,
    required String searchTerm,
    bool hasResults = false,
  });

  /// Returns [userId]'s recent project-search terms, most recently used first.
  ///
  /// Implementations may cap the number of entries returned. Returns an empty
  /// list when [userId] is empty.
  Future<List<String>> getRecentProjectSearches({required String userId});

  /// Removes [searchTerm] from [userId]'s recent project-search history.
  ///
  /// Does nothing when [userId] is empty or [searchTerm] is empty/whitespace.
  Future<void> deleteRecentProjectSearch({
    required String userId,
    required String searchTerm,
  });

  /// Returns up to 10 personalized project-search suggestion terms for [userId].
  ///
  /// Returns an empty list when [userId] is empty or no suggestions exist.
  Future<List<String>> getProjectSearchSuggestions({required String userId});
}
