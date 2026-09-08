// coverage:ignore-file
import 'package:construculator/libraries/project/data/models/project_dto.dart';

/// Provides raw data access for project setting mutations and single-project reads.
///
/// Implementations communicate directly with a remote data store (e.g., Supabase).
/// Methods throw on failure — callers are responsible for converting exceptions
/// to domain [Failure] objects.
abstract class ProjectSettingDataSource {
  /// Creates a new project from [projectDto] and returns the persisted row.
  ///
  /// Throws on network or database errors.
  Future<ProjectDto> createProject(ProjectDto projectDto);

  /// Fetches the current state of a single project by its [projectId].
  ///
  /// Throws if the project does not exist or if a network error occurs.
  Future<ProjectDto> fetchProjectSetting(String projectId);

  /// Persists the editable fields of [projectDto] to remote storage.
  ///
  /// Returns the updated [ProjectDto] as stored after the write.
  /// Throws on network or database errors.
  Future<ProjectDto> updateProject(ProjectDto projectDto);

  /// Permanently deletes the project identified by [projectId].
  ///
  /// Throws on network or database errors.
  Future<void> deleteProject(String projectId);
}
