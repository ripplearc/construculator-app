import 'dart:async';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/data/project_error_mapper.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';

/// Supabase-backed implementation of [ProjectSettingRepository].
class ProjectSettingRepositoryImpl implements ProjectSettingRepository {
  final ProjectSettingDataSource _dataSource;
  final ProjectPermissionDataSource _permissionDataSource;
  static final _logger = AppLogger().tag('ProjectSettingRepositoryImpl');

  final Map<String, StreamController<Either<Failure, Project>>>
  _settingControllers = {};
  final Map<String, StreamSubscription<ProjectDto?>> _changesSubscriptions = {};
  final Map<String, int> _refreshSequences = {};

  ProjectSettingRepositoryImpl({
    required ProjectSettingDataSource dataSource,
    required ProjectPermissionDataSource permissionDataSource,
  }) : _dataSource = dataSource,
       _permissionDataSource = permissionDataSource;

  @override
  Future<Either<Failure, Project>> getProjectSetting(String projectId) async {
    try {
      final dto = await _dataSource.fetchProjectSetting(projectId);
      return Right(dto.toDomain());
    } catch (error, stackTrace) {
      final failure = ProjectErrorMapper.toFailure(error);
      if (failure.errorType == ProjectErrorType.unexpectedError) {
        _logger.error(
          'Unexpected error while getting project setting for projectId: $projectId',
          error,
          stackTrace,
        );
      }
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, Project>> updateProject(Project project) async {
    final hasPermission = _permissionDataSource.hasProjectPermission(
      project.id,
      PermissionConstants.editProject,
    );
    if (!hasPermission) {
      return const Left(
        ProjectFailure(errorType: ProjectErrorType.permissionDenied),
      );
    }

    try {
      final dto = _toDtoFromEntity(project);
      final result = await _dataSource.updateProject(dto);
      return Right(result.toDomain());
    } catch (error, stackTrace) {
      final failure = ProjectErrorMapper.toFailure(error);
      if (failure.errorType == ProjectErrorType.unexpectedError) {
        _logger.error(
          'Unexpected error while updating project with id: ${project.id}',
          error,
          stackTrace,
        );
      }
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, void>> deleteProject(String projectId) async {
    final hasPermission = _permissionDataSource.hasProjectPermission(
      projectId,
      PermissionConstants.deleteProject,
    );
    if (!hasPermission) {
      return const Left(
        ProjectFailure(errorType: ProjectErrorType.permissionDenied),
      );
    }

    try {
      await _dataSource.deleteProject(projectId);
      return const Right(null);
    } catch (error, stackTrace) {
      final failure = ProjectErrorMapper.toFailure(error);
      if (failure.errorType == ProjectErrorType.unexpectedError) {
        _logger.error(
          'Unexpected error while deleting project with id: $projectId',
          error,
          stackTrace,
        );
      }
      return Left(failure);
    }
  }

  @override
  Stream<Either<Failure, Project>> watchProjectSetting(String projectId) {
    final existing = _settingControllers[projectId];
    if (existing?.isClosed == true) {
      _settingControllers.remove(projectId);
    }

    final controller = _settingControllers.putIfAbsent(
      projectId,
      () => StreamController<Either<Failure, Project>>.broadcast(
        onListen: () => _startWatchingSettingChanges(projectId),
        onCancel: () => _stopWatchingIfNoListeners(projectId),
      ),
    );
    return controller.stream;
  }

  void _startWatchingSettingChanges(String projectId) {
    if (_changesSubscriptions.containsKey(projectId)) {
      return;
    }

    _changesSubscriptions[projectId] = _dataSource
        .watchProjectChanges(projectId)
        .listen(
          (_) => _refreshProjectSetting(projectId),
          onError: (Object error, StackTrace stackTrace) {
            final controller = _settingControllers[projectId];
            if (controller?.isClosed == false) {
              controller?.addError(error, stackTrace);
            }
          },
        );

    _refreshProjectSetting(projectId);
  }

  void _stopWatchingIfNoListeners(String projectId) {
    final controller = _settingControllers[projectId];
    if (controller?.hasListener == true) {
      return;
    }
    _changesSubscriptions.remove(projectId)?.cancel();
    _settingControllers.remove(projectId);
    _refreshSequences.remove(projectId);
  }

  Future<void> _refreshProjectSetting(String projectId) async {
    final sequence = (_refreshSequences[projectId] ?? 0) + 1;
    _refreshSequences[projectId] = sequence;

    final result = await getProjectSetting(projectId);

    if (_refreshSequences[projectId] != sequence) return;

    final controller = _settingControllers[projectId];
    if (controller?.isClosed == false) {
      controller?.add(result);
    }
  }

  ProjectDto _toDtoFromEntity(Project project) {
    return ProjectDto(
      id: project.id,
      projectName: project.projectName,
      description: project.description,
      creatorUserId: project.creatorUserId,
      owningCompanyId: project.owningCompanyId,
      exportFolderLink: project.exportFolderLink,
      exportStorageProvider: project.exportStorageProvider?.name,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
      status: project.status,
    );
  }

  @override
  void dispose() {
    for (final subscription in _changesSubscriptions.values) {
      subscription.cancel();
    }
    _changesSubscriptions.clear();
    for (final controller in _settingControllers.values) {
      controller.close();
    }
    _settingControllers.clear();
    _refreshSequences.clear();
  }
}
