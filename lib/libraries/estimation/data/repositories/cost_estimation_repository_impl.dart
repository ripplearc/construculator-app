import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/data/models/pagination_state.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart'
    show EstimationSortOption;
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
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

  String _buildStreamKey(
    String projectId,
    EstimationSortOption sortBy,
    int? limit,
  ) {
    return '$projectId:${sortBy.name}:${limit ?? 'all'}';
  }

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
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) async {
    final streamKey = _buildStreamKey(projectId, sortBy, limit);
    try {
      _logger.debug(
        'Getting first page of estimations for project: $projectId (streamKey: $streamKey)',
      );

      _cachedEstimations[streamKey] = [];

      final fetchLimit = limit ?? defaultPageSize;

      final costEstimateDtos = await _dataSource.getEstimations(
        projectId: projectId,
        offset: 0,
        limit: fetchLimit,
        sortBy: sortBy,
        ascending: ascending,
      );

      final costEstimates = costEstimateDtos
          .map((dto) => dto.toDomain())
          .toList();

      final hasMore = costEstimates.length >= fetchLimit;

      _paginationStates[streamKey] = PaginationState(
        currentOffset: costEstimates.length,
        pageSize: fetchLimit,
        hasMore: hasMore,
      );

      _cachedEstimations[streamKey] = costEstimates;
      _emitToStream(streamKey, Right(costEstimates));

      _logger.debug(
        'Retrieved ${costEstimates.length} estimations (hasMore: $hasMore) '
        'for stream: $streamKey',
      );

      return Right(costEstimates);
    } catch (e) {
      final failure = _handleError(
        e,
        'getting first page of estimations',
        projectId: projectId,
      );
      _emitToStream(streamKey, Left(failure));
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) async {
    final streamKey = _buildStreamKey(projectId, sortBy, limit);
    final paginationState = _paginationStates[streamKey];

    if (paginationState == null) {
      _logger.warning(
        'loadMore called before initial fetch for stream: $streamKey',
      );
      return fetchInitialEstimations(
        projectId,
        sortBy: sortBy,
        ascending: ascending,
        limit: limit,
      );
    }

    if (!paginationState.hasMore) {
      _logger.debug('Skipping loadMore: hasMore=${paginationState.hasMore}');
      return Right(_cachedEstimations[streamKey] ?? []);
    }

    try {
      _logger.debug(
        'Loading more estimations for stream: $streamKey, '
        'offset: ${paginationState.currentOffset}',
      );

      final costEstimateDtos = await _dataSource.getEstimations(
        projectId: projectId,
        offset: paginationState.currentOffset,
        limit: paginationState.pageSize,
        sortBy: sortBy,
        ascending: ascending,
      );

      final newEstimates = costEstimateDtos
          .map((dto) => dto.toDomain())
          .toList();

      final hasMore = newEstimates.length >= paginationState.pageSize;

      final existingEstimates = _cachedEstimations[streamKey] ?? [];
      final allEstimates = [...existingEstimates, ...newEstimates];

      _paginationStates[streamKey] = PaginationState(
        currentOffset: allEstimates.length,
        pageSize: paginationState.pageSize,
        hasMore: hasMore,
      );

      _cachedEstimations[streamKey] = allEstimates;
      _emitToStream(streamKey, Right(allEstimates));

      _logger.debug(
        'Loaded ${newEstimates.length} more estimations '
        '(total: ${allEstimates.length}, hasMore: $hasMore) '
        'for stream: $streamKey',
      );

      return Right(allEstimates);
    } catch (e) {
      final failure = _handleError(
        e,
        'loading more estimations',
        projectId: projectId,
      );

      _emitToStream(streamKey, Left(failure));
      return Left(failure);
    }
  }

  @override
  bool hasMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) {
    final streamKey = _buildStreamKey(projectId, sortBy, limit);
    return _paginationStates[streamKey]?.hasMore ?? true;
  }

  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) {
    final streamKey = _buildStreamKey(projectId, sortBy, limit);
    _logger.debug('Watching cost estimations for stream: $streamKey');

    final controller = _streamControllers.putIfAbsent(streamKey, () {
      final newController =
          StreamController<Either<Failure, List<CostEstimate>>>.broadcast(
            onCancel: () {
              _logger.debug(
                'Stream cancelled for stream: $streamKey, cleaning up',
              );
              _streamControllers[streamKey]?.close();
              _streamControllers.remove(streamKey);
              _cachedEstimations.remove(streamKey);
              _paginationStates.remove(streamKey);
            },
          );
      fetchInitialEstimations(
        projectId,
        sortBy: sortBy,
        ascending: ascending,
        limit: limit,
      );
      return newController;
    });

    return controller.stream;
  }

  void _emitToStream(
    String streamKey,
    Either<Failure, List<CostEstimate>> result,
  ) {
    result.fold(
      (_) {},
      (estimations) => _cachedEstimations[streamKey] = estimations,
    );

    if (_streamControllers.containsKey(streamKey) &&
        _streamControllers[streamKey]?.isClosed == false) {
      _streamControllers[streamKey]?.add(result);
    }
  }

  CostEstimate? _getOriginalEstimation(String projectId, String estimationId) {
    final projectKeys = _cachedEstimations.keys.where(
      (k) => k.startsWith('$projectId:'),
    );
    for (final key in projectKeys) {
      final cached = _cachedEstimations[key] ?? [];
      final matchIndex = cached.indexWhere((e) => e.id == estimationId);
      if (matchIndex != -1) {
        return cached[matchIndex];
      }
    }

    final cachedEstimations = _cachedEstimations[projectId] ?? [];
    final matchIndex = cachedEstimations.indexWhere((e) => e.id == estimationId);
    return matchIndex == -1 ? null : cachedEstimations[matchIndex];
  }

  void _emitOptimisticUpdate({
    required String projectId,
    required String estimationId,
    required CostEstimate Function(CostEstimate) updateFn,
  }) {
    final projectKeys = _streamControllers.keys.where(
      (k) => k.startsWith('$projectId:'),
    );
    for (final key in projectKeys) {
      final cachedEstimations = _cachedEstimations[key] ?? [];
      final updatedList = cachedEstimations.map((e) {
        return e.id == estimationId ? updateFn(e) : e;
      }).toList();

      _emitToStream(key, Right(updatedList));
    }
  }

  void _finalizeOptimisticUpdate(
    String projectId,
    String estimationId,
    CostEstimate updatedEstimation,
  ) {
    final projectKeys = _streamControllers.keys.where(
      (k) => k.startsWith('$projectId:'),
    );
    for (final key in projectKeys) {
      final cachedEstimations = _cachedEstimations[key] ?? [];
      final updatedList = cachedEstimations.map((e) {
        return e.id == estimationId ? updatedEstimation : e;
      }).toList();

      _logger.debug(
        'Updating stream with locked/unlocked estimation for stream: $key',
      );

      _emitToStream(key, Right(updatedList));
    }
  }

  void _rollbackOptimisticUpdate(
    String projectId,
    String estimationId,
    CostEstimate? originalEstimation,
  ) {
    if (originalEstimation == null) return;

    final projectKeys = _streamControllers.keys.where(
      (k) => k.startsWith('$projectId:'),
    );
    for (final key in projectKeys) {
      final cachedEstimations = _cachedEstimations[key] ?? [];
      final updatedList = cachedEstimations.map((e) {
        return e.id == estimationId ? originalEstimation : e;
      }).toList();

      _emitToStream(key, Right(updatedList));
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
    final projectKeys = _streamControllers.keys.where(
      (k) => k.startsWith('$projectId:'),
    );
    for (final key in projectKeys) {
      final cachedEstimations = _cachedEstimations[key] ?? [];

      final updatedEstimations = [newEstimation, ...cachedEstimations];

      final paginationState = _paginationStates[key];
      if (paginationState != null) {
        _paginationStates[key] = paginationState.copyWith(
          currentOffset: paginationState.currentOffset + 1,
        );
      }

      _logger.debug('Updating stream with new estimation for stream: $key');

      _emitToStream(key, Right(updatedEstimations));
    }
  }

  void _updateStreamWithDeletedEstimation(
    String projectId,
    String estimationId,
  ) {
    final projectKeys = _streamControllers.keys.where(
      (k) => k.startsWith('$projectId:'),
    );
    for (final key in projectKeys) {
      final cachedEstimations = _cachedEstimations[key] ?? [];
      final updatedEstimations = cachedEstimations
          .where((estimation) => estimation.id != estimationId)
          .toList();

      final paginationState = _paginationStates[key];
      if (paginationState != null &&
          updatedEstimations.length < cachedEstimations.length) {
        _paginationStates[key] = paginationState.copyWith(
          currentOffset: (paginationState.currentOffset - 1).clamp(
            0,
            paginationState.currentOffset,
          ),
        );
      }

      _logger.debug(
        'Updating stream with deleted estimation for stream: $key, estimationId: $estimationId',
      );

      _emitToStream(key, Right(updatedEstimations));
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

  @override
  Future<Either<Failure, CostEstimate>> changeLockStatus({
    required String estimationId,
    required bool isLocked,
    required String projectId,
  }) async {
    final originalEstimation = _getOriginalEstimation(projectId, estimationId);

    try {
      _logger.debug(
        'Changing lock status for estimation: $estimationId to $isLocked',
      );

      _emitOptimisticUpdate(
        projectId: projectId,
        estimationId: estimationId,
        updateFn: (e) => e.copyWith(
          lockStatus: isLocked ? LockStatus.locked() : LockStatus.unlocked(),
        ),
      );

      final updatedDto = await _dataSource.changeLockStatus(
        estimationId: estimationId,
        isLocked: isLocked,
      );

      final updatedEstimation = updatedDto.toDomain();

      _finalizeOptimisticUpdate(projectId, estimationId, updatedEstimation);

      return Right(updatedEstimation);
    } catch (e) {
      _rollbackOptimisticUpdate(projectId, estimationId, originalEstimation);
      return Left(
        _handleError(
          e,
          'changing lock status',
          estimationId: estimationId,
          projectId: projectId,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CostEstimate>> renameEstimation({
    required String estimationId,
    required String newName,
    required String projectId,
  }) async {
    final originalEstimation = _getOriginalEstimation(projectId, estimationId);

    try {
      _logger.debug('Renaming estimation: $estimationId to $newName');

      _emitOptimisticUpdate(
        projectId: projectId,
        estimationId: estimationId,
        updateFn: (e) => e.copyWith(estimateName: newName),
      );

      final updatedDto = await _dataSource.renameEstimation(
        estimationId: estimationId,
        newName: newName,
      );

      final updatedEstimation = updatedDto.toDomain();

      _finalizeOptimisticUpdate(projectId, estimationId, updatedEstimation);

      return Right(updatedEstimation);
    } catch (e) {
      _rollbackOptimisticUpdate(projectId, estimationId, originalEstimation);
      return Left(
        _handleError(
          e,
          'renaming estimation',
          estimationId: estimationId,
          projectId: projectId,
        ),
      );
    }
  }
}
