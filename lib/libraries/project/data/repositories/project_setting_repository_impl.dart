import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase-backed implementation of [ProjectSettingRepository].
class ProjectSettingRepositoryImpl implements ProjectSettingRepository {
  final ProjectSettingDataSource _dataSource;
  // ignore: unused_field
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
  void dispose() {}
}
