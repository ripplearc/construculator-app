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
}
