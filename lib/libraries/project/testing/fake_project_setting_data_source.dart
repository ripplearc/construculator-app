import 'dart:async';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:stack_trace/stack_trace.dart';

/// Fake implementation of [ProjectSettingDataSource] for testing.
class FakeProjectSettingDataSource implements ProjectSettingDataSource {
  /// Tracks method calls for boundary assertions.
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Project returned by [fetchProjectSetting] and [updateProject].
  ProjectDto? projectToReturn;

  /// Controls whether [createProject] throws a [ServerException].
  bool shouldThrowOnCreate = false;

  /// Error message for [createProject] when [shouldThrowOnCreate] is true.
  String? createErrorMessage;

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

  /// Error message for [fetchProjectSetting] when [shouldThrowOnGet] is true.
  String? getErrorMessage;

  /// Error message for [updateProject] when [shouldThrowOnUpdate] is true.
  String? updateErrorMessage;

  /// Error message for [deleteProject] when [shouldThrowOnDelete] is true.
  String? deleteErrorMessage;

  /// Creates a [FakeProjectSettingDataSource].
  FakeProjectSettingDataSource();

  /// Returns [projectDto] as-is, simulating a successful create.
  @override
  Future<ProjectDto> createProject(ProjectDto projectDto) async {
    _methodCalls.add({'method': 'createProject', 'projectDto': projectDto});

    if (shouldThrowOnCreate) {
      throw ServerException(
        Trace.current(),
        Exception(createErrorMessage ?? 'Create project failed'),
      );
    }

    return projectDto;
  }

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

  /// Persists [projectDto] and updates [projectToReturn] so subsequent reads
  /// reflect the mutation.
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
    return projectDto;
  }

  /// Records deletion and clears stored state.
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
  }

  /// Returns a copy of all recorded method calls.
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns all calls for the given [methodName].
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Resets all flags, error messages, data, and recorded calls.
  void reset() {
    shouldThrowOnCreate = false;
    shouldThrowOnGet = false;
    shouldThrowOnUpdate = false;
    shouldThrowOnDelete = false;
    createErrorMessage = null;
    getErrorMessage = null;
    updateErrorMessage = null;
    deleteErrorMessage = null;
    projectToReturn = null;
    fetchExceptionToThrow = null;
    _methodCalls.clear();
  }

  /// Releases resources held by this fake.
  void dispose() {}
}
