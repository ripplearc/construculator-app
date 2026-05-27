import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';

/// Repository that manages a single project's settings.
///
/// Mutating methods perform a permission check before delegating to the
/// data layer. Permission keys are declared in [PermissionConstants].
///
/// Details: https://ripplearc.youtrack.cloud/issue/CA-250
abstract class ProjectSettingRepository {
  /// Returns the current state of the project identified by [projectId].
  ///
  /// Returns [Right] with the [Project] on success, or [Left] with a
  /// [Failure] if the project is not found or a data error occurs.
  Future<Either<Failure, Project>> getProjectSetting(String projectId);

  /// Persists editable fields of [project] to remote storage.
  ///
  /// Checks [PermissionConstants.editProject] before delegating.
  /// Returns [Left] with a [ProjectFailure] whose [errorType] is
  /// [ProjectErrorType.permissionDenied] when the caller lacks the permission.
  Future<Either<Failure, Project>> updateProject(Project project);

  /// Permanently deletes the project identified by [projectId].
  ///
  /// Checks [PermissionConstants.deleteProject] before delegating.
  /// Returns [Left] with a [ProjectFailure] whose [errorType] is
  /// [ProjectErrorType.permissionDenied] when the caller lacks the permission.
  Future<Either<Failure, void>> deleteProject(String projectId);

  /// Releases subscriptions and stream controllers held by this repository.
  void dispose();
}
