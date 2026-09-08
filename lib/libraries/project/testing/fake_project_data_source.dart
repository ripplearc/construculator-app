import 'dart:async';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:stack_trace/stack_trace.dart';

/// Fake implementation of [ProjectDataSource] for testing.
class FakeProjectDataSource implements ProjectDataSource {
  /// Projects returned by [getOwnedProjects].
  List<ProjectDto> ownedProjects = [];

  /// Projects returned by [getSharedProjects].
  List<ProjectDto> sharedProjects = [];

  /// Project returned by [getProject].
  ProjectDto? projectToReturn;

  /// If non-null, thrown directly by [getProject].
  Object? getProjectExceptionToThrow;

  /// Controls whether [getOwnedProjects] throws a [ServerException].
  bool shouldThrowOnGetOwned = false;

  /// Controls whether [getSharedProjects] throws a [ServerException].
  bool shouldThrowOnGetShared = false;

  /// Controls whether [getProject] throws a [ServerException].
  bool shouldThrowOnGetProject = false;

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  @override
  Future<List<ProjectDto>> getOwnedProjects(String userId) async {
    if (shouldThrowOnGetOwned) {
      throw ServerException(
        Trace.current(),
        Exception('Get owned projects failed'),
      );
    }
    return ownedProjects;
  }

  @override
  Future<List<ProjectDto>> getSharedProjects(String userId) async {
    if (shouldThrowOnGetShared) {
      throw ServerException(
        Trace.current(),
        Exception('Get shared projects failed'),
      );
    }
    return sharedProjects;
  }

  @override
  Stream<void> watchProjectChanges(String userId) => _changesController.stream;

  @override
  Future<ProjectDto> getProject(String projectId) async {
    final exception = getProjectExceptionToThrow;
    if (exception != null) {
      throw exception;
    }

    if (shouldThrowOnGetProject) {
      throw ServerException(
        Trace.current(),
        Exception('Get project failed'),
      );
    }

    final project = projectToReturn;
    if (project == null) {
      throw NotFoundException(
        Trace.current(),
        Exception('No project configured in FakeProjectDataSource'),
      );
    }

    return project;
  }

  /// Emits a change event on the watch stream.
  void emitProjectChange() => _changesController.add(null);

  /// Emits an error on the watch stream.
  void emitError(Object error) => _changesController.addError(error);

  /// Resets all configured state.
  void reset() {
    ownedProjects = [];
    sharedProjects = [];
    projectToReturn = null;
    getProjectExceptionToThrow = null;
    shouldThrowOnGetOwned = false;
    shouldThrowOnGetShared = false;
    shouldThrowOnGetProject = false;
  }

  /// Releases resources held by this fake.
  void dispose() {
    _changesController.close();
  }
}
