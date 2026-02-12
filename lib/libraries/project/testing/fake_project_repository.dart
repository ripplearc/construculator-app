import 'dart:async';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:stack_trace/stack_trace.dart';

/// Fake implementation of ProjectRepository for testing
class FakeProjectRepository implements ProjectRepository {
  /// Tracks method calls for assertions
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Tracks project data for assertions during [getProject]
  final Map<String, Project> _projects = {};

  /// Tracks permission results keyed by "projectId:permissionKey:userId"
  final Map<String, bool> _permissions = {};

  /// Controls whether [getProject] throws an exception
  bool shouldThrowOnGetProject = false;

  /// Error message for get project.
  /// Used to specify the error message thrown when [getProject] is attempted
  String? getProjectErrorMessage;

  /// Used to specify the type of exception thrown when [getProject] is attempted
  SupabaseExceptionType? getProjectExceptionType;

  /// Used to specify the error code thrown during [getProject]
  PostgresErrorCode? postgrestErrorCode;

  /// Controls whether [hasPermission] throws an exception
  bool shouldThrowOnHasPermission = false;

  /// Error message for has permission.
  /// Used to specify the error message thrown when [hasPermission] is attempted
  String? hasPermissionErrorMessage;

  /// Used to specify the type of exception thrown when [hasPermission] is attempted
  SupabaseExceptionType? hasPermissionExceptionType;

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
  Future<bool> hasPermission({
    required String projectId,
    required String permissionKey,
    required String userCredentialId,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'hasPermission',
      'projectId': projectId,
      'permissionKey': permissionKey,
      'userCredentialId': userCredentialId,
    });

    if (shouldThrowOnHasPermission) {
      _throwConfiguredException(
        hasPermissionExceptionType,
        hasPermissionErrorMessage ?? 'Has permission check failed',
      );
    }

    final key = '$projectId:$permissionKey:$userCredentialId';
    return _permissions[key] ?? false;
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
  }

  /// Clears project data for a specific project ID
  void clearProject(String id) {
    _projects.remove(id);
  }

  /// Sets the permission result for a specific project, permission key, and user.
  void setPermission({
    required String projectId,
    required String permissionKey,
    required String userCredentialId,
    required bool hasPermission,
  }) {
    final key = '$projectId:$permissionKey:$userCredentialId';
    _permissions[key] = hasPermission;
  }

  /// Clears all permission data
  void clearPermissions() {
    _permissions.clear();
  }

  /// Clears all project data and method calls
  void clearAllData() {
    _projects.clear();
    _permissions.clear();
    _methodCalls.clear();
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
    getProjectErrorMessage = null;
    getProjectExceptionType = null;
    postgrestErrorCode = null;
    shouldThrowOnHasPermission = false;
    hasPermissionErrorMessage = null;
    hasPermissionExceptionType = null;
    shouldDelayOperations = false;
    completer = null;

    clearAllData();
    clearMethodCalls();
  }
}
