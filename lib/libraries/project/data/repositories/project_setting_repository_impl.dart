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

  ProjectSettingRepositoryImpl({
    required ProjectSettingDataSource dataSource,
    required ProjectPermissionDataSource permissionDataSource,
  }) : _dataSource = dataSource,
       _permissionDataSource = permissionDataSource;

  @override
  Future<Either<Failure, Project>> createProject(Project project) async {
    try {
      final dto = _toDtoFromEntity(project);
      final result = await _dataSource.createProject(dto);
      return Right(result.toDomain());
    } catch (error, stackTrace) {
      return Left(
        _handleError(
          error,
          'creating project with name: ${project.projectName}',
          stackTrace,
        ),
      );
    }
  }

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
        _handleError(error, 'deleting project with id: $projectId', stackTrace),
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

  static const _unexpectedErrorTypes = {
    ProjectErrorType.unexpectedError,
    ProjectErrorType.unexpectedDatabaseError,
    ProjectErrorType.parsingError,
  };

  ProjectFailure _handleError(
    Object error,
    String operation,
    StackTrace stackTrace,
  ) {
    final failure = ProjectErrorMapper.toFailure(error);
    if (_unexpectedErrorTypes.contains(failure.errorType)) {
      _logger.error('Error $operation: $error', error, stackTrace);
    } else {
      _logger.warning(
        'Error $operation: ${failure.errorType.name}',
        error,
        stackTrace,
      );
    }
    return failure;
  }

  @override
  void dispose() {
    // No subscriptions or stream controllers to release in this PR's scope.
  }
}
