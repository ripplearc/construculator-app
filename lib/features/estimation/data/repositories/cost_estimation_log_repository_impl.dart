import 'dart:async';
import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/models/pagination_state.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_log_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// Implementation of [CostEstimationLogRepository] that manages log retrieval and pagination.
///
/// This repository coordinates between the data source layer and the domain layer,
/// handling:
/// - Pagination state management per estimation
/// - Error handling and conversion to domain failures
/// - DTO to domain entity conversion
class CostEstimationLogRepositoryImpl implements CostEstimationLogRepository {
  final CostEstimationLogDataSource dataSource;
  static final _logger = AppLogger().tag('CostEstimationLogRepositoryImpl');

  final Map<String, PaginationState> _paginationStates = {};

  static const int _defaultPageSize = 10;

  CostEstimationLogRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<CostEstimationLog>>> fetchInitialLogs(
    String estimateId,
  ) async {
    _logger.debug(
      'Fetching initial logs for estimate: $estimateId, pageSize: $_defaultPageSize',
    );

    try {
      const initialState = PaginationState(
        currentOffset: 0,
        pageSize: _defaultPageSize,
        hasMore: true,
      );

      _paginationStates[estimateId] = initialState;

      final dtos = await dataSource.getEstimationLogs(
        estimateId: estimateId,
        rangeFrom: 0,
        rangeTo: _defaultPageSize - 1,
      );

      final hasMore = dtos.length == _defaultPageSize;

      _paginationStates[estimateId] = initialState.copyWith(
        currentOffset: _defaultPageSize,
        hasMore: hasMore,
      );

      final logs = dtos.map((dto) => dto.toDomain()).toList();

      _logger.info(
        'Fetched ${logs.length} initial logs for estimate: $estimateId, hasMore: $hasMore',
      );

      return Right(logs);
    } catch (e) {
      return _handleError(e, 'fetching initial logs', estimateId);
    }
  }

  @override
  Future<Either<Failure, List<CostEstimationLog>>> loadMoreLogs(
    String estimateId,
  ) async {
    final state = _paginationStates[estimateId];

    if (state == null || !state.hasMore) {
      _logger.debug(
        'Skipping loadMore for estimate: $estimateId, '
        'stateExists: ${state != null}, hasMore: ${state?.hasMore ?? false}',
      );
      return const Right([]);
    }

    _logger.debug(
      'Loading more logs for estimate: $estimateId, offset: ${state.currentOffset}',
    );

    try {
      final dtos = await dataSource.getEstimationLogs(
        estimateId: estimateId,
        rangeFrom: state.currentOffset,
        rangeTo: state.currentOffset + state.pageSize - 1,
      );

      _paginationStates[estimateId] = state.copyWith(
        currentOffset: state.currentOffset + state.pageSize,
        hasMore: dtos.length == state.pageSize,
      );

      final logs = dtos.map((dto) => dto.toDomain()).toList();

      _logger.info(
        'Loaded ${logs.length} more logs for estimate: $estimateId, '
        'hasMore: ${_paginationStates[estimateId]?.hasMore ?? false}',
      );

      return Right(logs);
    } catch (e) {
      return _handleError(e, 'loading more logs', estimateId);
    }
  }

  @override
  bool hasMoreLogs(String estimateId) {
    final state = _paginationStates[estimateId];
    return state?.hasMore ?? false;
  }

  @override
  void dispose() {
    _paginationStates.clear();
  }

  Left<Failure, List<CostEstimationLog>> _handleError(
    Object error,
    String operation,
    String estimateId,
  ) {
    if (error is TimeoutException) {
      _logger.error(
        'Timeout error $operation for estimate: $estimateId, '
        'message=${error.message}, duration=${error.duration}',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.timeoutError),
      );
    } else if (error is SocketException) {
      _logger.warning(
        'Connection error $operation for estimate: $estimateId, '
        'message=${error.message}, address=${error.address}, port=${error.port}, osError=${error.osError}',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.connectionError),
      );
    } else if (error is FormatException) {
      _logger.error(
        'Parsing error $operation for estimate: $estimateId, '
        'message=${error.message}, source=${error.source}',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.parsingError),
      );
    } else if (error is TypeError) {
      _logger.error(
        'Parsing error $operation for estimate: $estimateId, '
        'error: ${error.toString()}',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.parsingError),
      );
    } else {
      _logger.error(
        'Unexpected error $operation for estimate: $estimateId, error: $error',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.unexpectedError),
      );
    }
  }
}
