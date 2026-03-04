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

  /// Tracks accessible projects returned by [getProjects].
  final List<Project> _accessibleProjects = [];

  /// Controls whether [getProject] throws an exception
  bool shouldThrowOnGetProject = false;

  /// Controls whether [getProjects] throws an exception.
  bool shouldThrowOnGetProjects = false;

  /// Error message for get project.
  /// Used to specify the error message thrown when [getProject] is attempted
  String? getProjectErrorMessage;

  /// Error message for get projects.
  /// Used to specify the error message thrown when [getProjects] is attempted.
  String? getProjectsErrorMessage;

  /// Used to specify the type of exception thrown when [getProject] is attempted
  SupabaseExceptionType? getProjectExceptionType;

  /// Used to specify the type of exception thrown when [getProjects] is attempted.
  SupabaseExceptionType? getProjectsExceptionType;

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
  Future<List<Project>> getProjects() async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({'method': 'getProjects'});

    if (shouldThrowOnGetProjects) {
      _throwConfiguredException(
        getProjectsExceptionType,
        getProjectsErrorMessage ?? 'Get projects failed',
      );
    }

    return List<Project>.from(_accessibleProjects);
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
  }

  /// Clears project data for a specific project ID
  void clearProject(String id) {
    _projects.remove(id);
    _accessibleProjects.removeWhere((project) => project.id == id);
  }

  /// Sets accessible projects returned by [getProjects].
  void setAccessibleProjects(List<Project> projects) {
    _accessibleProjects
      ..clear()
      ..addAll(projects);
  }

  /// Clears all project data and method calls
  void clearAllData() {
    _projects.clear();
    _accessibleProjects.clear();
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
    shouldThrowOnGetProjects = false;
    getProjectErrorMessage = null;
    getProjectsErrorMessage = null;
    getProjectExceptionType = null;
    getProjectsExceptionType = null;
    postgrestErrorCode = null;
    shouldDelayOperations = false;
    completer = null;

    clearAllData();
    clearMethodCalls();
  }
}
