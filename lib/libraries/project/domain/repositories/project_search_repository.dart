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
}
