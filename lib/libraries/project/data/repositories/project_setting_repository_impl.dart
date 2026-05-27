import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase-backed implementation of [ProjectSettingRepository].
///
/// Checks permissions via [ProjectPermissionDataSource] before delegating
/// mutations to [ProjectSettingDataSource].
class ProjectSettingRepositoryImpl implements ProjectSettingRepository {
  final ProjectSettingDataSource _dataSource;
  final ProjectPermissionDataSource _permissionDataSource;
  static final _logger = AppLogger().tag('ProjectSettingRepositoryImpl');

  StreamController<Either<Failure, Project>>? _settingController;
  StreamSubscription<void>? _changesSubscription;
  String? _watchedProjectId;

  ProjectSettingRepositoryImpl({
    required ProjectSettingDataSource dataSource,
    required ProjectPermissionDataSource permissionDataSource,
  }) : _dataSource = dataSource,
       _permissionDataSource = permissionDataSource;

  @override
  Future<Either<Failure, Project>> getProjectSetting(String projectId) async {
    try {
      final dto = await _dataSource.getProjectSetting(projectId);
      return Right(dto.toDomain());
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting project setting for projectId: $projectId',
        error,
        stackTrace,
      );
      return Left(_handleError(error, 'getting project setting'));
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
      _logger.error(
        'Error while updating project with id: ${project.id}',
        error,
        stackTrace,
      );
      return Left(_handleError(error, 'updating project'));
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
      _logger.error(
        'Error while deleting project with id: $projectId',
        error,
        stackTrace,
      );
      return Left(_handleError(error, 'deleting project'));
    }
  }

  @override
  Stream<Either<Failure, Project>> watchProjectSetting(String projectId) {
    _watchedProjectId = projectId;
    final controller =
        _settingController ??= StreamController<Either<Failure, Project>>.broadcast(
          onListen: _startWatchingSettingChanges,
          onCancel: _stopWatchingIfNoListeners,
        );
    return controller.stream;
  }

  void _startWatchingSettingChanges() {
    if (_changesSubscription != null) {
      return;
    }

    final projectId = _watchedProjectId;
    if (projectId == null || projectId.isEmpty) {
      return;
    }

    _changesSubscription = _dataSource
        .watchProjectChanges(projectId)
        .listen(
          (_) => _refreshProjectSetting(),
          onError: (Object error, StackTrace stackTrace) {
            _logger.error(
              'Error while watching project setting changes for projectId: $projectId',
              error,
              stackTrace,
            );
            _settingController?.addError(error, stackTrace);
          },
        );

    _refreshProjectSetting();
  }

  void _stopWatchingIfNoListeners() {
    if (_settingController?.hasListener == true) {
      return;
    }
    _changesSubscription?.cancel();
    _changesSubscription = null;
    _watchedProjectId = null;
  }

  Future<void> _refreshProjectSetting() async {
    final projectId = _watchedProjectId;
    if (projectId == null || projectId.isEmpty) {
      return;
    }
    final result = await getProjectSetting(projectId);
    if (_settingController?.isClosed == false) {
      _settingController?.add(result);
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

  Failure _handleError(Object error, String operation) {
    if (error is ServerException) {
      _logger.error('Server error $operation: ${error.exception}');
      return const ProjectFailure(errorType: ProjectErrorType.notFoundError);
    }

    if (error is TimeoutException) {
      _logger.error('Timeout error $operation: ${error.message}');
      return const ProjectFailure(errorType: ProjectErrorType.timeoutError);
    }

    if (error is SocketException) {
      _logger.error('Connection error $operation: ${error.message}');
      return const ProjectFailure(errorType: ProjectErrorType.connectionError);
    }

    if (error is TypeError) {
      _logger.error('Parsing error $operation: ${error.toString()}');
      return const ProjectFailure(errorType: ProjectErrorType.parsingError);
    }

    if (error is supabase.PostgrestException) {
      _logger.error(
        'PostgreSQL error $operation: code=${error.code}, message=${error.message}',
      );
      final postgresErrorCode = PostgresErrorCode.fromCode(error.code);
      if (postgresErrorCode == PostgresErrorCode.noDataFound) {
        return const ProjectFailure(errorType: ProjectErrorType.notFoundError);
      } else if (postgresErrorCode == PostgresErrorCode.connectionFailure ||
          postgresErrorCode == PostgresErrorCode.unableToConnect ||
          postgresErrorCode == PostgresErrorCode.connectionDoesNotExist) {
        return const ProjectFailure(
          errorType: ProjectErrorType.connectionError,
        );
      }
      return const ProjectFailure(
        errorType: ProjectErrorType.unexpectedDatabaseError,
      );
    }

    _logger.error('Unexpected error $operation: $error');
    return UnexpectedFailure();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    _changesSubscription = null;
    _settingController?.close();
    _settingController = null;
    _watchedProjectId = null;
  }
}
