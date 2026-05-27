import 'dart:async';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:stack_trace/stack_trace.dart';

/// Fake implementation of [ProjectSettingDataSource] for testing.
class FakeProjectSettingDataSource implements ProjectSettingDataSource {
  /// Tracks method calls for boundary assertions.
  final List<Map<String, dynamic>> _methodCalls = [];

  /// The [ProjectDto] returned by [fetchProjectSetting] and [updateProject].
  ProjectDto? projectToReturn;

  /// Controls whether [getProjectSetting] throws a [ServerException].
  bool shouldThrowOnGet = false;

  /// Controls whether [updateProject] throws a [ServerException].
  bool shouldThrowOnUpdate = false;

  /// Controls whether [deleteProject] throws a [ServerException].
  bool shouldThrowOnDelete = false;

  /// Controls whether [watchProjectChanges] throws a [ServerException].
  bool shouldThrowOnWatch = false;

  /// Error messages used when the corresponding [shouldThrowOn*] flag is set.
  String? getErrorMessage;

  /// Error message for [updateProject] when [shouldThrowOnUpdate] is true.
  String? updateErrorMessage;

  /// Error message for [deleteProject] when [shouldThrowOnDelete] is true.
  String? deleteErrorMessage;

  final StreamController<ProjectDto?> _changesController =
      StreamController<ProjectDto?>.broadcast();

  /// Creates a [FakeProjectSettingDataSource].
  FakeProjectSettingDataSource();

  @override
  Future<ProjectDto> fetchProjectSetting(String projectId) async {
    _methodCalls.add({'method': 'fetchProjectSetting', 'projectId': projectId});

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

  @override
  Future<ProjectDto> updateProject(ProjectDto projectDto) async {
    _methodCalls.add({'method': 'updateProject', 'projectDto': projectDto});

    if (shouldThrowOnUpdate) {
      throw ServerException(
        Trace.current(),
        Exception(updateErrorMessage ?? 'Update project failed'),
      );
    }

    return projectToReturn ?? projectDto;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    _methodCalls.add({'method': 'deleteProject', 'projectId': projectId});

    if (shouldThrowOnDelete) {
      throw ServerException(
        Trace.current(),
        Exception(deleteErrorMessage ?? 'Delete project failed'),
      );
    }
  }

  @override
  Stream<ProjectDto?> watchProjectChanges(String projectId) {
    _methodCalls.add({'method': 'watchProjectChanges', 'projectId': projectId});

    if (shouldThrowOnWatch) {
      throw ServerException(
        Trace.current(),
        Exception('Watch project changes failed'),
      );
    }

    return _changesController.stream;
  }

  /// Emits a change event to active [watchProjectChanges] subscribers.
  void emitChange() {
    _changesController.add(projectToReturn);
  }

  /// Emits an error to active [watchProjectChanges] subscribers.
  void emitError(Object error, [StackTrace? stackTrace]) {
    _changesController.addError(error, stackTrace);
  }

  /// Returns a copy of all recorded method calls.
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns all calls for the given [methodName].
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Resets all flags, error messages, data, and recorded calls.
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
  }

  /// Releases resources held by this fake.
  void dispose() {
    _changesController.close();
  }
}
