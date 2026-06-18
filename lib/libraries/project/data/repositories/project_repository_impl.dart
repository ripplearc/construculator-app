import 'dart:async';

import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/project_error_mapper.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';

/// Remote implementation of the project repository.
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectDataSource _projectDataSource;
  final ProjectSettingDataSource _projectSettingDataSource;
  final ProjectPermissionDataSource _permissionDataSource;
  final CurrentProjectNotifier _currentProjectNotifier;
  static final _logger = AppLogger().tag('ProjectRepositoryImpl');
  StreamController<List<Project>>? _projectsController;
  StreamSubscription<void>? _projectChangesSubscription;
  String? _watchUserId;
  List<Project>? _lastEmittedProjects;
  bool _isRefreshing = false;
  bool _hasPendingRefresh = false;

  /// Creates a [ProjectRepositoryImpl].
  ///
  /// [projectDataSource] provides remote project list and watch operations.
  /// [projectSettingDataSource] provides single-project fetch and mutation operations.
  /// [permissionDataSource] provides JWT-based permission checks.
  /// [currentProjectNotifier] is read in [findCurrentProjectForUser] to resolve the selected project id.
  ProjectRepositoryImpl({
    required ProjectDataSource projectDataSource,
    required ProjectSettingDataSource projectSettingDataSource,
    required ProjectPermissionDataSource permissionDataSource,
    required CurrentProjectNotifier currentProjectNotifier,
  }) : _projectDataSource = projectDataSource,
       _projectSettingDataSource = projectSettingDataSource,
       _permissionDataSource = permissionDataSource,
       _currentProjectNotifier = currentProjectNotifier;

  @override
  Future<Project> getProject(String id) async {
    try {
      // TODO: Add local cache lookup once ProjectLocalDataSource is implemented (out of scope for CA-225)
      final dto = await _projectSettingDataSource.fetchProjectSetting(id);
      return dto.toDomain();
    } catch (error, stackTrace) {
      final failure = ProjectErrorMapper.toFailure(error);
      _logFailure('getting project by id: $id', failure, stackTrace);
      throw failure;
    }
  }

  @override
  Future<List<Project>> getProjects(String userId) async {
    try {
      if (userId.isEmpty) {
        return [];
      }

      final ownedProjects = await _projectDataSource.getOwnedProjects(userId);
      final sharedProjects = await _projectDataSource.getSharedProjects(userId);

      final projectsById = <String, Project>{};
      for (final projectDto in [...ownedProjects, ...sharedProjects]) {
        final project = projectDto.toDomain();
        final existing = projectsById[project.id];
        if (existing == null || project.updatedAt.isAfter(existing.updatedAt)) {
          projectsById[project.id] = project;
        }
      }

      final projects = projectsById.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return projects;
    } catch (error, stackTrace) {
      final failure = ProjectErrorMapper.toFailure(error);
      _logFailure('getting accessible projects', failure, stackTrace);
      throw failure;
    }
  }

  @override
  Stream<List<Project>> watchProjects(String userId) {
    _watchUserId = userId;
    final controller = _projectsController ??=
        StreamController<List<Project>>.broadcast(
          onListen: _startWatchingProjectChanges,
          onCancel: _stopWatchingIfNoListeners,
        );

    return controller.stream;
  }

  void _startWatchingProjectChanges() {
    if (_projectChangesSubscription != null) {
      return;
    }

    final userId = _watchUserId;
    if (userId == null || userId.isEmpty) {
      _emitProjects(const []);
      return;
    }

    _projectChangesSubscription = _projectDataSource
        .watchProjectChanges(userId)
        .listen(
          (_) => _refreshProjects(),
          onError: (Object error, StackTrace stackTrace) {
            final failure = ProjectErrorMapper.toFailure(error);
            _logFailure('watching project changes', failure, stackTrace);
            _projectsController?.addError(failure, stackTrace);
          },
        );

    _refreshProjects();
  }

  void _stopWatchingIfNoListeners() {
    if (_projectsController?.hasListener == true) {
      return;
    }
    _projectChangesSubscription?.cancel();
    _projectChangesSubscription = null;
    _watchUserId = null;
    _lastEmittedProjects = null;
  }

  Future<void> _refreshProjects() async {
    if (_isRefreshing) {
      _hasPendingRefresh = true;
      return;
    }
    _isRefreshing = true;

    try {
      do {
        _hasPendingRefresh = false;
        try {
          final userId = _watchUserId;
          final projects = userId != null && userId.isNotEmpty
              ? await getProjects(userId)
              : <Project>[];
          _emitProjects(projects);
        } catch (error, stackTrace) {
          final failure = error is ProjectFailure
              ? error
              : ProjectErrorMapper.toFailure(error);
          _logFailure('refreshing accessible projects', failure, stackTrace);
          _projectsController?.addError(failure, stackTrace);
          break;
        }
      } while (_hasPendingRefresh);
    } finally {
      _isRefreshing = false;
    }
  }

  void _emitProjects(List<Project> projects) {
    final lastEmittedProjects = _lastEmittedProjects;
    if (lastEmittedProjects != null &&
        _projectsAreEqual(lastEmittedProjects, projects)) {
      return;
    }

    _lastEmittedProjects = List<Project>.from(projects);
    if (_projectsController?.isClosed == false) {
      _projectsController?.add(projects);
    }
  }

  static const _unexpectedErrorTypes = {
    ProjectErrorType.unexpectedError,
    ProjectErrorType.unexpectedDatabaseError,
    ProjectErrorType.parsingError,
  };

  void _logFailure(
    String operation,
    ProjectFailure failure,
    StackTrace stackTrace,
  ) {
    final message = 'Error while $operation: ${failure.errorType.name}';
    if (_unexpectedErrorTypes.contains(failure.errorType)) {
      _logger.error(message, stackTrace.toString());
    } else {
      _logger.warning(message, stackTrace.toString());
    }
  }

  @override
  Future<Project?> findCurrentProjectForUser(String userId) async {
    if (userId.isEmpty) return null;
    final projectId = _currentProjectNotifier.currentProjectId;
    if (projectId == null || projectId.isEmpty) return null;
    try {
      final projects = await getProjects(userId);
      for (final project in projects) {
        if (project.id == projectId) return project;
      }
      return null;
    } catch (error, stackTrace) {
      _logger.warning(
        'Could not resolve current project for user $userId: $error',
        stackTrace.toString(),
      );
      return null;
    }
  }

  @override
  void dispose() {
    _projectChangesSubscription?.cancel();
    _projectChangesSubscription = null;
    _projectsController?.close();
    _projectsController = null;
    _watchUserId = null;
    _lastEmittedProjects = null;
    _isRefreshing = false;
    _hasPendingRefresh = false;
  }

  bool _projectsAreEqual(List<Project> first, List<Project> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var i = 0; i < first.length; i++) {
      if (first[i].id != second[i].id ||
          first[i].updatedAt != second[i].updatedAt) {
        return false;
      }
    }
    return true;
  }

  @override
  List<String> getProjectPermissions(String projectId) {
    return _permissionDataSource.getProjectPermissions(projectId);
  }

  @override
  bool hasProjectPermission(String projectId, String permissionKey) {
    return _permissionDataSource.hasProjectPermission(projectId, permissionKey);
  }
}
