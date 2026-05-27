import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase-backed implementation of [ProjectSettingRepository].
class ProjectSettingRepositoryImpl implements ProjectSettingRepository {
  final ProjectSettingDataSource _dataSource;

  static final _logger = AppLogger().tag('ProjectSettingRepositoryImpl');

  ProjectSettingRepositoryImpl({required ProjectSettingDataSource dataSource})
    : _dataSource = dataSource;

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
