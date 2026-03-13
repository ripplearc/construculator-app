import 'package:construculator/libraries/project/data/models/project_dto.dart';

/// Interface that abstracts remote project data operations.
abstract class ProjectDataSource {
  /// Returns projects owned by the given [userId].
  Future<List<ProjectDto>> getOwnedProjects(String userId);

  /// Returns projects shared with the given [userId].
  Future<List<ProjectDto>> getSharedProjects(String userId);

  /// Emits whenever project accessibility data changes for [userId].
  Stream<void> watchProjectChanges(String userId);
}
