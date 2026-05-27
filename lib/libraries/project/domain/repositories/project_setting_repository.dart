import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';

/// Repository that manages a single project's settings.
///
/// Mutating operations and live updates are introduced in follow-up PRs
/// of the stack.
///
/// Details: https://ripplearc.youtrack.cloud/issue/CA-250
abstract class ProjectSettingRepository {
  /// Returns the current state of the project identified by [projectId].
  ///
  /// Returns [Right] with the [Project] on success, or [Left] with a
  /// [Failure] if the project is not found or a data error occurs.
  Future<Either<Failure, Project>> getProjectSetting(String projectId);

  /// Releases subscriptions and stream controllers held by this repository.
  void dispose();
}
