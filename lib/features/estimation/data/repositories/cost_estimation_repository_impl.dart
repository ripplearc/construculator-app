import 'dart:async';
import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class CostEstimationRepositoryImpl implements CostEstimationRepository {
  final CostEstimationDataSource _dataSource;
  static final _logger = AppLogger().tag('CostEstimationRepositoryImpl');

  CostEstimationRepositoryImpl({required CostEstimationDataSource dataSource})
    : _dataSource = dataSource;

  Failure _handleError(Object error, String operation) {
    if (error is TimeoutException) {
      _logger.error('Timeout error $operation');
      return EstimationFailure(errorType: EstimationErrorType.timeoutError);
    }

    if (error is SocketException) {
      _logger.error('Connection error $operation');
      return EstimationFailure(errorType: EstimationErrorType.connectionError);
    }

    if (error is FormatException) {
      _logger.error('Parsing error $operation');
      return EstimationFailure(errorType: EstimationErrorType.parsingError);
    }

    if (error is supabase.PostgrestException) {
      _logger.error('PostgreSQL error $operation: ${error.code}');
      final postgresErrorCode = PostgresErrorCode.fromCode(error.code);
      if (postgresErrorCode == PostgresErrorCode.connectionFailure ||
          postgresErrorCode == PostgresErrorCode.unableToConnect ||
          postgresErrorCode == PostgresErrorCode.connectionDoesNotExist) {
        return EstimationFailure(
          errorType: EstimationErrorType.connectionError,
        );
      } else {
        return EstimationFailure(
          errorType: EstimationErrorType.unexpectedDatabaseError,
        );
      }
    }

    _logger.error('Unexpected error $operation: $error');
    return UnexpectedFailure();
  }

  @override
  Future<Either<Failure, List<CostEstimate>>> getEstimations(
    String projectId,
  ) async {
    try {
      _logger.debug('Getting cost estimations for project: $projectId');

      final costEstimateDtos = await _dataSource.getEstimations(projectId);

      final costEstimates = costEstimateDtos
          .map((dto) => dto.toDomain())
          .toList();

      _logger.debug(
        'Successfully retrieved ${costEstimates.length} cost estimations for project: $projectId',
      );

      return Right(costEstimates);
    } catch (e) {
      return Left(_handleError(e, 'getting cost estimations for project'));
    }
  }

  @override
  Future<Either<Failure, CostEstimate>> createEstimation(
    CostEstimate estimation,
  ) async {
    try {
      _logger.debug('Creating cost estimation: ${estimation.id}');

      final costEstimateDto = CostEstimateDto.fromDomain(estimation);
      final createdDto = await _dataSource.createEstimation(costEstimateDto);

      final createdEstimation = createdDto.toDomain();

      _logger.debug(
        'Successfully created cost estimation: ${createdEstimation.id}',
      );
      return Right(createdEstimation);
    } catch (e) {
      return Left(_handleError(e, 'creating cost estimation'));
    }
  }
}
