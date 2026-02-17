import 'dart:async';
import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/estimation/data/models/pagination_state.dart';
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

  final Map<String, StreamController<Either<Failure, List<CostEstimate>>>>
  _streamControllers = {};
  final Map<String, List<CostEstimate>> _cachedEstimations = {};
  final Map<String, PaginationState> _paginationStates = {};

  static const int defaultPageSize = 10;

  CostEstimationRepositoryImpl({required CostEstimationDataSource dataSource})
    : _dataSource = dataSource;

  Failure _handleError(
    Object error,
    String operation, {
    String? projectId,
    String? estimationId,
  }) {
    final context = _buildContextString(
      projectId: projectId,
      estimationId: estimationId,
    );

    if (error is TimeoutException) {
      _logger.error(
        'Timeout error $operation$context: '
        'message=${error.message}, duration=${error.duration}',
      );
      return EstimationFailure(errorType: EstimationErrorType.timeoutError);
    }

    if (error is SocketException) {
      _logger.error(
        'Connection error $operation$context: '
        'message=${error.message}, address=${error.address}, '
        'port=${error.port}, osError=${error.osError}',
      );
      return EstimationFailure(errorType: EstimationErrorType.connectionError);
    }

    if (error is TypeError) {
      _logger.error(
        'Parsing error $operation$context: ${error.toString()}',
        'returning parsing failure',
      );
      return EstimationFailure(errorType: EstimationErrorType.parsingError);
    }

    if (error is supabase.PostgrestException) {
      _logger.error(
        'PostgreSQL error $operation$context: '
        'code=${error.code}, message=${error.message}, '
        'details=${error.details}, hint=${error.hint}',
      );
      final postgresErrorCode = PostgresErrorCode.fromCode(error.code);
      if (postgresErrorCode == PostgresErrorCode.noDataFound) {
        return EstimationFailure(errorType: EstimationErrorType.notFoundError);
      } else if (postgresErrorCode == PostgresErrorCode.connectionFailure ||
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

    _logger.error('Unexpected error $operation$context: $error');
    return UnexpectedFailure();
  }

  String _buildContextString({String? projectId, String? estimationId}) {
    final parts = <String>[];
    if (projectId != null) {
      parts.add('projectId=$projectId');
    }
    if (estimationId != null) {
      parts.add('estimationId=$estimationId');
    }
    return parts.isEmpty ? '' : ' [${parts.join(', ')}]';
  }

  @override
  Future<Either<Failure, List<CostEstimate>>> fetchInitialEstimations(
    String projectId,
  ) async {
    try {
      _logger.debug(
        'Getting first page of estimations for project: $projectId',
      );

      _cachedEstimations[projectId] = [];

      final costEstimateDtos = await _dataSource.getEstimations(
        projectId: projectId,
        offset: 0,
        limit: defaultPageSize,
      );

      final costEstimates = costEstimateDtos
          .map((dto) => dto.toDomain())
          .toList();

      final hasMore = costEstimates.length >= defaultPageSize;

      _paginationStates[projectId] = PaginationState(
        currentOffset: costEstimates.length,
        pageSize: defaultPageSize,
        hasMore: hasMore,
      );

      _cachedEstimations[projectId] = costEstimates;
      _emitToStream(projectId, Right(costEstimates));

      _logger.debug(
        'Retrieved ${costEstimates.length} estimations (hasMore: $hasMore) '
        'for project: $projectId',
      );

      return Right(costEstimates);
    } catch (e) {
      final failure = _handleError(
        e,
        'getting first page of estimations',
        projectId: projectId,
      );
      _emitToStream(projectId, Left(failure));
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId,
  ) async {
    final paginationState = _paginationStates[projectId];

    if (paginationState == null) {
      _logger.warning(
        'loadMore called before initial fetch for project: $projectId',
      );
      return fetchInitialEstimations(projectId);
    }

    if (!paginationState.hasMore) {
      _logger.debug('Skipping loadMore: hasMore=${paginationState.hasMore}');
      return Right(_cachedEstimations[projectId] ?? []);
    }

    try {
      _logger.debug(
        'Loading more estimations for project: $projectId, '
        'offset: ${paginationState.currentOffset}',
      );

      final costEstimateDtos = await _dataSource.getEstimations(
        projectId: projectId,
        offset: paginationState.currentOffset,
        limit: paginationState.pageSize,
      );

      final newEstimates = costEstimateDtos
          .map((dto) => dto.toDomain())
          .toList();

      final hasMore = newEstimates.length >= paginationState.pageSize;

      final existingEstimates = _cachedEstimations[projectId] ?? [];
      final allEstimates = [...existingEstimates, ...newEstimates];

      _paginationStates[projectId] = PaginationState(
        currentOffset: allEstimates.length,
        pageSize: paginationState.pageSize,
        hasMore: hasMore,
      );

      _cachedEstimations[projectId] = allEstimates;
      _emitToStream(projectId, Right(allEstimates));

      _logger.debug(
        'Loaded ${newEstimates.length} more estimations '
        '(total: ${allEstimates.length}, hasMore: $hasMore) '
        'for project: $projectId',
      );

      return Right(allEstimates);
    } catch (e) {
      final failure = _handleError(
        e,
        'loading more estimations',
        projectId: projectId,
      );

      _emitToStream(projectId, Left(failure));
      return Left(failure);
    }
  }

  @override
  bool hasMoreEstimations(String projectId) {
    return _paginationStates[projectId]?.hasMore ?? true;
  }

  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId,
  ) {
    _logger.debug('Watching cost estimations for project: $projectId');

    final controller = _streamControllers.putIfAbsent(projectId, () {
      final newController =
          StreamController<Either<Failure, List<CostEstimate>>>.broadcast(
            onCancel: () {
              _logger.debug(
                'Stream cancelled for project: $projectId, cleaning up',
              );
              _streamControllers[projectId]?.close();
              _streamControllers.remove(projectId);
              _cachedEstimations.remove(projectId);
              _paginationStates.remove(projectId);
            },
          );
      fetchInitialEstimations(projectId);
      return newController;
    });

    return controller.stream;
  }

  void _emitToStream(
    String projectId,
    Either<Failure, List<CostEstimate>> result,
  ) {
    result.fold(
      (_) {},
      (estimations) => _cachedEstimations[projectId] = estimations,
    );

    if (_streamControllers.containsKey(projectId) &&
        _streamControllers[projectId]?.isClosed == false) {
      _streamControllers[projectId]?.add(result);
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

      _updateStreamWithNewEstimation(estimation.projectId, createdEstimation);

      return Right(createdEstimation);
    } catch (e) {
      return Left(
        _handleError(
          e,
          'creating cost estimation',
          projectId: estimation.projectId,
          estimationId: estimation.id,
        ),
      );
    }
  }

  void _updateStreamWithNewEstimation(
    String projectId,
    CostEstimate newEstimation,
  ) {
    if (_streamControllers.containsKey(projectId)) {
      final cachedEstimations = _cachedEstimations[projectId] ?? [];

      final updatedEstimations = [newEstimation, ...cachedEstimations];

      final paginationState = _paginationStates[projectId];
      if (paginationState != null) {
        _paginationStates[projectId] = paginationState.copyWith(
          currentOffset: paginationState.currentOffset + 1,
        );
      }

      _logger.debug(
        'Updating stream with new estimation for project: $projectId',
      );

      _emitToStream(projectId, Right(updatedEstimations));
    }
  }

  void _updateStreamWithDeletedEstimation(
    String projectId,
    String estimationId,
  ) {
    if (_streamControllers.containsKey(projectId)) {
      final cachedEstimations = _cachedEstimations[projectId] ?? [];
      final updatedEstimations = cachedEstimations
          .where((estimation) => estimation.id != estimationId)
          .toList();

      final paginationState = _paginationStates[projectId];
      if (paginationState != null &&
          updatedEstimations.length < cachedEstimations.length) {
        _paginationStates[projectId] = paginationState.copyWith(
          currentOffset: (paginationState.currentOffset - 1).clamp(
            0,
            paginationState.currentOffset,
          ),
        );
      }

      _logger.debug(
        'Updating stream with deleted estimation for project: $projectId, estimationId: $estimationId',
      );

      _emitToStream(projectId, Right(updatedEstimations));
    }
  }

  @override
  void dispose() {
    _logger.debug('Disposing repository and cleaning up resources');

    for (final controller in _streamControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }

    _streamControllers.clear();
    _cachedEstimations.clear();
    _paginationStates.clear();
  }

  @override
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  ) async {
    try {
      _logger.debug(
        'Deleting cost estimation: Estimation id: $estimationId, Project id: $projectId',
      );

      _updateStreamWithDeletedEstimation(projectId, estimationId);

      await _dataSource.deleteEstimation(estimationId);

      _logger.debug(
        'Successfully deleted cost estimation: Estimation id: $estimationId, Project id: $projectId',
      );
      return const Right(null);
    } catch (e) {
      final failure = _handleError(
        e,
        'deleting cost estimation',
        estimationId: estimationId,
        projectId: projectId,
      );

      await fetchInitialEstimations(projectId);

      return Left(failure);
    }
  }
}
