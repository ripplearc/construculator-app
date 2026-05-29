import 'dart:async';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stack_trace/stack_trace.dart';

/// Fake implementation of [ProjectSettingDataSource] for testing.
class FakeProjectSettingDataSource implements ProjectSettingDataSource {
  /// Tracks method calls for boundary assertions.
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Per-project stream controllers. Each project gets its own [BehaviorSubject]
  /// so cross-project isolation can be verified and subscriptions receive the
  /// current snapshot immediately on listen.
  final Map<String, BehaviorSubject<ProjectDto?>> _projectControllers = {};

  /// Project returned by [fetchProjectSetting] and [updateProject].
  ProjectDto? projectToReturn;

  /// Controls whether [fetchProjectSetting] throws a [ServerException].
  bool shouldThrowOnGet = false;

  /// If non-null, this exception/object will be thrown directly by
  /// [fetchProjectSetting] to allow tests to simulate different failures
  /// (e.g., [TimeoutException]). This takes precedence over [shouldThrowOnGet].
  Object? fetchExceptionToThrow;

  /// Controls whether [updateProject] throws a [ServerException].
  bool shouldThrowOnUpdate = false;

  /// Controls whether [deleteProject] throws a [ServerException].
  bool shouldThrowOnDelete = false;

  /// Controls whether [watchProjectChanges] throws a [ServerException].
  bool shouldThrowOnWatch = false;

  /// Error message for [fetchProjectSetting] when [shouldThrowOnGet] is true.
  String? getErrorMessage;

  /// Error message for [updateProject] when [shouldThrowOnUpdate] is true.
  String? updateErrorMessage;

  /// Error message for [deleteProject] when [shouldThrowOnDelete] is true.
  String? deleteErrorMessage;

  /// Creates a [FakeProjectSettingDataSource].
  FakeProjectSettingDataSource();

  /// Returns the configured [projectToReturn] for the given [projectId].
  @override
  Future<ProjectDto> fetchProjectSetting(String projectId) async {
    _methodCalls.add({'method': 'fetchProjectSetting', 'projectId': projectId});

    final exception = fetchExceptionToThrow;
    if (exception != null) {
      throw exception;
    }

    if (shouldThrowOnGet) {
      throw ServerException(
        Trace.current(),
        Exception(getErrorMessage ?? 'Get project setting failed'),
      );
    }

    final project = projectToReturn;
    if (project == null) {
      throw ServerException(
        Trace.current(),
        Exception('No project configured in FakeProjectSettingDataSource'),
      );
    }

    return project;
  }

  /// Persists [projectDto] and updates stored state so subsequent reads and
  /// watch streams reflect the mutation.
  @override
  Future<ProjectDto> updateProject(ProjectDto projectDto) async {
    _methodCalls.add({'method': 'updateProject', 'projectDto': projectDto});

    if (shouldThrowOnUpdate) {
      throw ServerException(
        Trace.current(),
        Exception(updateErrorMessage ?? 'Update project failed'),
      );
    }

    projectToReturn = projectDto;
    _getOrCreateController(projectDto.id).add(projectDto);
    return projectDto;
  }

  /// Records deletion, clears stored state, and closes the project's stream so
  /// subsequent reads, watches, and stream completions reflect the removal.
  @override
  Future<void> deleteProject(String projectId) async {
    _methodCalls.add({'method': 'deleteProject', 'projectId': projectId});

    if (shouldThrowOnDelete) {
      throw ServerException(
        Trace.current(),
        Exception(deleteErrorMessage ?? 'Delete project failed'),
      );
    }

    projectToReturn = null;
    final controller = _projectControllers.remove(projectId);
    if (controller != null) {
      controller.add(null);
      controller.close();
    }
  }

  /// Returns a per-project stream that immediately emits the current snapshot
  /// on subscription, then emits on each [emitChange] call.
  @override
  Stream<ProjectDto?> watchProjectChanges(String projectId) {
    _methodCalls.add({'method': 'watchProjectChanges', 'projectId': projectId});

    if (shouldThrowOnWatch) {
      throw ServerException(
        Trace.current(),
        Exception('Watch project changes failed'),
      );
    }

    return _getOrCreateController(projectId).stream;
  }

  /// Emits [projectToReturn] to subscribers watching [projectId].
  void emitChange(String projectId) {
    _getOrCreateController(projectId).add(projectToReturn);
  }

  /// Emits an error to subscribers watching [projectId].
  void emitError(Object error, String projectId, [StackTrace? stackTrace]) {
    _getOrCreateController(projectId).addError(error, stackTrace);
  }

  BehaviorSubject<ProjectDto?> _getOrCreateController(String projectId) {
    return _projectControllers.putIfAbsent(
      projectId,
      () => BehaviorSubject<ProjectDto?>.seeded(projectToReturn),
    );
  }

  /// Returns a copy of all recorded method calls.
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns all calls for the given [methodName].
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Resets all flags, error messages, data, recorded calls, and stream state.
  void reset() {
    shouldThrowOnGet = false;
    shouldThrowOnUpdate = false;
    shouldThrowOnDelete = false;
    shouldThrowOnWatch = false;
    getErrorMessage = null;
    updateErrorMessage = null;
    deleteErrorMessage = null;
    projectToReturn = null;
    _methodCalls.clear();
    fetchExceptionToThrow = null;
    for (final controller in _projectControllers.values) {
      controller.close();
    }
    _projectControllers.clear();
  }

  /// Releases resources held by this fake.
  void dispose() {
    for (final controller in _projectControllers.values) {
      controller.close();
    }
    _projectControllers.clear();
  }
}
