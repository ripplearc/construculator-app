import 'dart:async';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';

/// Fake implementation of [ProjectSettingRepository] for testing.
class FakeProjectSettingRepository implements ProjectSettingRepository {
  /// Tracks method calls for boundary assertions.
  final List<Map<String, dynamic>> _methodCalls = [];

  int _activeWatchListeners = 0;
  bool _isDisposed = false;

  /// The [Project] returned by [getProjectSetting] and [updateProject].
  Project? projectToReturn;

  /// When true, [getProjectSetting] returns a [Left] failure.
  bool shouldFailOnGet = false;

  /// When true, [updateProject] returns a [Left] failure.
  bool shouldFailOnUpdate = false;

  /// When true, [deleteProject] returns a [Left] failure.
  bool shouldFailOnDelete = false;

  /// When true, [watchProjectSetting] returns a [Left] failure via the stream.
  bool shouldFailOnWatch = false;

  /// The [Failure] returned when a [shouldFailOn*] flag is true.
  ///
  /// Defaults to [ProjectFailure] with [ProjectErrorType.unexpectedError].
  Failure failureToReturn = const ProjectFailure(
    errorType: ProjectErrorType.unexpectedError,
  );

  late StreamController<Either<Failure, Project>> _watchController;

  /// Creates a [FakeProjectSettingRepository].
  FakeProjectSettingRepository() {
    _watchController = _createWatchController();
  }

  StreamController<Either<Failure, Project>> _createWatchController() {
    return StreamController<Either<Failure, Project>>.broadcast(
      onListen: () {
        _activeWatchListeners++;
      },
      onCancel: () {
        if (_activeWatchListeners > 0) {
          _activeWatchListeners--;
        }
      },
    );
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

  @override
  Stream<Either<Failure, Project>> watchProjectSetting(String projectId) {
    _methodCalls.add({'method': 'watchProjectSetting', 'projectId': projectId});

    if (shouldFailOnWatch) {
      return Stream.value(Left(failureToReturn));
    }

    return _watchController.stream;
  }

  void _emitToWatchController(Either<Failure, Project> result) {
    if (_isDisposed ||
        _watchController.isClosed ||
        _activeWatchListeners == 0) {
      return;
    }

    try {
      _watchController.add(result);
    } on StateError {
      // Guards against concurrent dispose() closing the controller.
    }
  }

  void _emitWatchControllerError(Object error, [StackTrace? stackTrace]) {
    if (_isDisposed ||
        _watchController.isClosed ||
        _activeWatchListeners == 0) {
      return;
    }

    try {
      _watchController.addError(error, stackTrace);
    } on StateError {
      // Guards against concurrent dispose() closing the controller.
    }
  }

  @override
  void dispose() {
    if (_isDisposed || _watchController.isClosed) {
      return;
    }

    _isDisposed = true;
    _watchController.close();
  }

  /// Emits a [Right] with [project] to active [watchProjectSetting] subscribers.
  void emitProject(Project project) {
    _emitToWatchController(Right(project));
  }

  /// Emits a [Left] with [failure] to active [watchProjectSetting] subscribers.
  void emitFailure(Failure failure) {
    _emitToWatchController(Left(failure));
  }

  /// Emits an error event to active [watchProjectSetting] subscribers.
  void emitStreamError(Object error, [StackTrace? stackTrace]) {
    _emitWatchControllerError(error, stackTrace);
  }

  /// Returns a copy of all recorded method calls.
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns all calls for the given [methodName].
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Resets all flags, data, and recorded calls.
  ///
  /// Recreates the watch controller if it was closed by a prior [dispose] call,
  /// so the fake can model a full repository lifecycle across test scenarios.
  void reset() {
    shouldFailOnGet = false;
    shouldFailOnUpdate = false;
    shouldFailOnDelete = false;
    shouldFailOnWatch = false;
    failureToReturn = const ProjectFailure(
      errorType: ProjectErrorType.unexpectedError,
    );
    projectToReturn = null;
    _methodCalls.clear();
    _isDisposed = false;
    _activeWatchListeners = 0;
    if (_watchController.isClosed) {
      _watchController = _createWatchController();
    }
  }
}
