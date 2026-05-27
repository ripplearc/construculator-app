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
class ProjectSettingRepositoryImpl implements ProjectSettingRepository {
  final ProjectSettingDataSource _dataSource;
  final ProjectPermissionDataSource _permissionDataSource;
  static final _logger = AppLogger().tag('ProjectSettingRepositoryImpl');

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
      return Left(
        _handleError(
          error,
          'getting project setting for projectId: $projectId',
          stackTrace,
        ),
      );
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
      return Left(
        _handleError(
          error,
          'updating project with id: ${project.id}',
          stackTrace,
        ),
      );
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
      return Left(
        _handleError(
          error,
          'deleting project with id: $projectId',
          stackTrace,
        ),
      );
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

  Failure _handleError(Object error, String operation, StackTrace stackTrace) {
    if (error is NotFoundException) {
      _logger.warning(
        'Not found $operation: ${error.exception}',
        error,
        stackTrace,
      );
      return const ProjectFailure(errorType: ProjectErrorType.notFoundError);
    }

    if (error is ServerException) {
      _logger.warning(
        'Server error $operation: ${error.exception}',
        error,
        stackTrace,
      );
      return const ProjectFailure(
        errorType: ProjectErrorType.unexpectedDatabaseError,
      );
    }

    if (error is TimeoutException) {
      _logger.warning(
        'Timeout error $operation: ${error.message}',
        error,
        stackTrace,
      );
      return const ProjectFailure(errorType: ProjectErrorType.timeoutError);
    }

    if (error is SocketException || error is NetworkException) {
      _logger.warning(
        'Connection error $operation: ${error is SocketException ? (error).message : error.toString()}',
        error,
        stackTrace,
      );
      return const ProjectFailure(errorType: ProjectErrorType.connectionError);
    }

    if (error is TypeError) {
      _logger.warning(
        'Parsing error $operation: ${error.toString()}',
        error,
        stackTrace,
      );
      return const ProjectFailure(errorType: ProjectErrorType.parsingError);
    }

    if (error is supabase.PostgrestException) {
      _logger.warning(
        'PostgreSQL error $operation: code=${error.code}, message=${error.message}',
        error,
        stackTrace,
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

    _logger.error('Unexpected error $operation: $error', error, stackTrace);
    return UnexpectedFailure();
  }

  @override
  void dispose() {
    // No subscriptions or stream controllers to release in the read-only MVP.
  }
}
