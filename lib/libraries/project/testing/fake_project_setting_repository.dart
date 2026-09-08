import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';

/// Fake implementation of [ProjectSettingRepository] for testing.
class FakeProjectSettingRepository implements ProjectSettingRepository {
  // Tracks method calls for boundary assertions.
  final List<Map<String, dynamic>> _methodCalls = [];

  /// The persisted project state. Read by [getProjectSetting], mutated by
  /// [updateProject], and cleared by [deleteProject].
  Project? projectToReturn;

  /// When true, [createProject] returns a [Left] failure.
  bool shouldFailOnCreate = false;

  /// When true, [getProjectSetting] returns a [Left] failure.
  bool shouldFailOnGet = false;

  /// When true, [updateProject] returns a [Left] failure.
  bool shouldFailOnUpdate = false;

  /// When true, [deleteProject] returns a [Left] failure.
  bool shouldFailOnDelete = false;

  /// The [Failure] returned when a [shouldFailOn*] flag is true.
  ///
  /// Defaults to [ProjectFailure] with [ProjectErrorType.unexpectedError].
  Failure failureToReturn = const ProjectFailure(
    errorType: ProjectErrorType.unexpectedError,
  );

  @override
  Future<Either<Failure, Project>> createProject(Project project) async {
    _methodCalls.add({'method': 'createProject', 'project': project});

    if (shouldFailOnCreate) {
      return Left(failureToReturn);
    }

    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> getProjectSetting(String projectId) async {
    _methodCalls.add({'method': 'getProjectSetting', 'projectId': projectId});

    if (shouldFailOnGet) {
      return Left(failureToReturn);
    }

    final project = projectToReturn;
    if (project == null) {
      return const Left(
        ProjectFailure(errorType: ProjectErrorType.notFoundError),
      );
    }

    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> updateProject(Project project) async {
    _methodCalls.add({'method': 'updateProject', 'project': project});

    if (shouldFailOnUpdate) {
      return Left(failureToReturn);
    }

    projectToReturn = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, void>> deleteProject(String projectId) async {
    _methodCalls.add({'method': 'deleteProject', 'projectId': projectId});

    if (shouldFailOnDelete) {
      return Left(failureToReturn);
    }

    projectToReturn = null;
    return const Right(null);
  }

  /// Returns a copy of all recorded method calls.
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns all calls for the given [methodName].
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Resets all flags, data, and recorded calls.
  void reset() {
    shouldFailOnCreate = false;
    shouldFailOnGet = false;
    shouldFailOnUpdate = false;
    shouldFailOnDelete = false;
    failureToReturn = const ProjectFailure(
      errorType: ProjectErrorType.unexpectedError,
    );
    projectToReturn = null;
    _methodCalls.clear();
  }

  @override
  void dispose() {}
}
