import 'dart:async';
import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
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
    } on TimeoutException {
      _logger.error(
        'Timeout error getting cost estimations for project $projectId',
      );
      return Left(
        EstimationFailure(errorType: EstimationErrorType.timeoutError),
      );
    } on SocketException {
      _logger.error(
        'Connection error getting cost estimations for project $projectId',
      );
      return Left(
        EstimationFailure(errorType: EstimationErrorType.connectionError),
      );
    } on FormatException {
      _logger.error(
        'Parsing error getting cost estimations for project $projectId',
      );
      return Left(
        EstimationFailure(errorType: EstimationErrorType.parsingError),
      );
    } on supabase.PostgrestException catch (e) {
      _logger.error(
        'PostgreSQL error getting cost estimations for project $projectId: ${e.code}',
      );
      final postgresErrorCode = PostgresErrorCode.fromCode(e.code);
      if (postgresErrorCode == PostgresErrorCode.connectionFailure ||
          postgresErrorCode == PostgresErrorCode.unableToConnect ||
          postgresErrorCode == PostgresErrorCode.connectionDoesNotExist) {
        return Left(
          EstimationFailure(errorType: EstimationErrorType.connectionError),
        );
      } else {
        return Left(
          EstimationFailure(
            errorType: EstimationErrorType.unexpectedDatabaseError,
          ),
        );
      }
    } catch (e) {
      _logger.error(
        'Unexpected error getting cost estimations for project $projectId: $e',
      );
      return Left(UnexpectedFailure());
    }
  }
}
