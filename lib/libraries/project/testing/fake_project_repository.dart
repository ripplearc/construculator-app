import 'dart:async';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:stack_trace/stack_trace.dart';

/// Fake implementation of ProjectRepository for testing
class FakeProjectRepository implements ProjectRepository {
  /// Tracks method calls for assertions
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Tracks project data for assertions during [getProject]
  final Map<String, Project> _projects = {};

  /// Tracks accessible projects returned by [getProjects].
  final List<Project> _accessibleProjects = [];

  /// Emits project list updates for [watchProjects].
  final StreamController<List<Project>> _projectsController =
      StreamController<List<Project>>.broadcast();

  /// Last emitted project list for deduplication (matches real impl behavior).
  List<Project>? _lastEmitted;

  /// Tracks permissions by project ID for testing
  final Map<String, List<String>> _projectPermissions = {};

  /// Controls whether [getProject] throws an exception
  bool shouldThrowOnGetProject = false;

  /// Controls whether [getProjects] throws an exception.
  bool shouldThrowOnGetProjects = false;

  /// Controls whether [watchProjects] throws an exception.
  bool shouldThrowOnWatchProjects = false;

  /// Error message for get project.
  /// Used to specify the error message thrown when [getProject] is attempted
  String? getProjectErrorMessage;

  /// Error message for get projects.
  /// Used to specify the error message thrown when [getProjects] is attempted.
  String? getProjectsErrorMessage;

  /// Error message for watch projects.
  /// Used to specify the error thrown when [watchProjects] is attempted.
  String? watchProjectsErrorMessage;

  /// Used to specify the type of exception thrown when [getProject] is attempted
  SupabaseExceptionType? getProjectExceptionType;

  /// Used to specify the type of exception thrown when [getProjects] is attempted.
  SupabaseExceptionType? getProjectsExceptionType;

  /// Used to specify the type of exception thrown when [watchProjects] is attempted.
  SupabaseExceptionType? watchProjectsExceptionType;

  /// Used to specify the error code thrown during [getProject]
  PostgresErrorCode? postgrestErrorCode;

  /// Controls whether operations should be delayed
  bool shouldDelayOperations = false;

  /// Controls when a delayed future is completed
  Completer? completer;

  /// Constructor for fake project repository
  FakeProjectRepository();

  @override
  Future<Project> getProject(String id) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({'method': 'getProject', 'id': id});

    if (shouldThrowOnGetProject) {
      _throwConfiguredException(
        getProjectExceptionType,
        getProjectErrorMessage ?? 'Get project failed',
      );
    }

    final project = _projects[id];
    if (project == null) {
      throw ServerException(
        Trace.current(),
        Exception('Project with id $id not found'),
      );
    }

    return project;
  }

  @override
  Future<List<Project>> getProjects(String userId) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({'method': 'getProjects', 'userId': userId});

    if (shouldThrowOnGetProjects) {
      _throwConfiguredException(
        getProjectsExceptionType,
        getProjectsErrorMessage ?? 'Get projects failed',
      );
    }

    return List<Project>.from(_accessibleProjects);
  }

  @override
  Stream<List<Project>> watchProjects(String userId) async* {
    _methodCalls.add({'method': 'watchProjects', 'userId': userId});

    if (shouldThrowOnWatchProjects) {
      _throwConfiguredException(
        watchProjectsExceptionType,
        watchProjectsErrorMessage ?? 'Watch projects failed',
      );
    }

    yield* Stream.fromFuture(
      Future.value(List<Project>.from(_accessibleProjects)),
    );
    yield* _projectsController.stream;
  }

  void _throwConfiguredException(
    SupabaseExceptionType? exceptionType,
    String message,
  ) {
    switch (exceptionType) {
      case SupabaseExceptionType.timeout:
        throw TimeoutException(message);
      case SupabaseExceptionType.type:
        throw TypeError();
      default:
        throw ServerException(Trace.current(), Exception(message));
    }
  }

  /// Adds project data for a specific project ID
  void addProject(String id, Project project) {
    _projects[id] = project;
    final existingIndex = _accessibleProjects.indexWhere((p) => p.id == id);
    if (existingIndex == -1) {
      _accessibleProjects.add(project);
    } else {
      _accessibleProjects[existingIndex] = project;
    }
    _emitProjectsUpdate();
  }

  /// Clears project data for a specific project ID
  void clearProject(String id) {
    _projects.remove(id);
    _accessibleProjects.removeWhere((project) => project.id == id);
    _emitProjectsUpdate();
  }

  /// Sets accessible projects returned by [getProjects].
  void setAccessibleProjects(List<Project> projects) {
    _accessibleProjects
      ..clear()
      ..addAll(projects);
    _emitProjectsUpdate();
  }

  /// Clears all project data and method calls
  void clearAllData() {
    _projects.clear();
    _accessibleProjects.clear();
    _methodCalls.clear();
    _projectPermissions.clear();
    _lastEmitted = null;
    _emitProjectsUpdate();
  }

  /// Emits current accessible projects to active [watchProjects] listeners.
  void emitProjectsUpdate() {
    _emitProjectsUpdate();
  }

  /// Emits an error to active [watchProjects] listeners.
  void emitProjectsError(Object error, [StackTrace? stackTrace]) {
    _projectsController.addError(error, stackTrace);
  }

  void _emitProjectsUpdate() {
    if (_projectsController.isClosed) {
      return;
    }
    final current = List<Project>.from(_accessibleProjects);
    final lastEmitted = _lastEmitted;
    if (lastEmitted != null && _listEquals(lastEmitted, current)) {
      return;
    }
    _lastEmitted = current;
    _projectsController.add(current);
  }

  bool _listEquals(List<Project> a, List<Project> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  /// Returns a list of all method calls
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns the last method call
  Map<String, dynamic>? getLastMethodCall() =>
      _methodCalls.isEmpty ? null : _methodCalls.last;

  /// Returns a list of all method calls for a given method name
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Clears all method calls
  void clearMethodCalls() {
    _methodCalls.clear();
  }

  /// Resets all fake configurations, clears data
  void reset() {
    shouldThrowOnGetProject = false;
    shouldThrowOnGetProjects = false;
    shouldThrowOnWatchProjects = false;
    getProjectErrorMessage = null;
    getProjectsErrorMessage = null;
    watchProjectsErrorMessage = null;
    getProjectExceptionType = null;
    getProjectsExceptionType = null;
    watchProjectsExceptionType = null;
    postgrestErrorCode = null;
    shouldDelayOperations = false;
    completer = null;
    _lastEmitted = null;

    clearAllData();
    clearMethodCalls();
    _projectPermissions.clear();
  }

  @override
  void dispose() {
    _projectsController.close();
  }

  @override
  List<String> getProjectPermissions(String projectId) {
    _methodCalls.add({
      'method': 'getProjectPermissions',
      'projectId': projectId,
    });
    return List<String>.from(_projectPermissions[projectId] ?? []);
  }

  @override
  bool hasProjectPermission(String projectId, String permissionKey) {
    _methodCalls.add({
      'method': 'hasProjectPermission',
      'projectId': projectId,
      'permissionKey': permissionKey,
    });
    return _projectPermissions[projectId]?.contains(permissionKey) ?? false;
  }

  /// Sets permissions for a specific project (for testing)
  void setProjectPermissions(String projectId, List<String> permissions) {
    _projectPermissions[projectId] = List<String>.from(permissions);
  }

  /// Clears permissions for a specific project (for testing)
  void clearProjectPermissions(String projectId) {
    _projectPermissions.remove(projectId);
  }
}
