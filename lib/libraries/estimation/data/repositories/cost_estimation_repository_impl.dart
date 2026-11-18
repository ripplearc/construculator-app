import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/powersync_cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/data/models/pagination_state.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart'
    show EstimationSortOption;
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Implementation of [CostEstimationRepository] that reads the list from the
/// phone's PowerSync copy and writes a create, rename, lock change and delete
/// there too.
///
/// Isolates reactive estimation streams, pagination state, and cache
/// by a composite key of `projectId + sortBy + limit`, so multiple
/// query contexts for the same project do not share state. Paging raises the
/// limit of the local watch instead of fetching offsets.
///
/// A write lands in the phone's database at once, so the list watch shows it
/// without waiting for a sync, and PowerSync uploads it later. A write never
/// waits for the server.
class CostEstimationRepositoryImpl implements CostEstimationRepository {
  final CostEstimationDataSource _dataSource;
  final PowerSyncCostEstimationDataSource _localDataSource;
  static final _logger = AppLogger().tag('CostEstimationRepositoryImpl');

  final Map<String, StreamController<Either<Failure, List<CostEstimate>>>>
  _streamControllers = {};
  final Map<String, List<CostEstimate>> _cachedEstimations = {};
  final Map<String, PaginationState> _paginationStates = {};
  final Map<String, int> _visibleLimits = {};
  final Map<String, StreamSubscription<List<CostEstimateDto>>>
  _localSubscriptions = {};
  final Map<String, Completer<Either<Failure, List<CostEstimate>>>>
  _firstResults = {};

  static const int defaultPageSize = 10;

  CostEstimationRepositoryImpl({
    required this._dataSource,
    required this._localDataSource,
  });

  String _buildStreamKey(
    String projectId,
    EstimationSortOption sortBy,
    bool ascending,
    int? limit,
  ) {
    return '$projectId:${sortBy.name}:${ascending ? 'asc' : 'desc'}:${limit ?? 'all'}';
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
  }) {
    final streamKey = _buildStreamKey(projectId, sortBy, ascending, limit);
    _logger.debug(
      'Getting first page of estimations for project: $projectId (streamKey: $streamKey)',
    );
    _cachedEstimations[streamKey] = [];
    final visibleLimit = limit ?? defaultPageSize;
    _visibleLimits[streamKey] = visibleLimit;
    return _watchLocalEstimations(
      streamKey,
      projectId,
      sortBy,
      ascending,
      visibleLimit,
    );
  }

  @override
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) {
    final streamKey = _buildStreamKey(projectId, sortBy, ascending, limit);
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
      return Future.value(Right(_cachedEstimations[streamKey] ?? []));
    }

    final visibleLimit =
        (_visibleLimits[streamKey] ?? defaultPageSize) +
        paginationState.pageSize;
    _visibleLimits[streamKey] = visibleLimit;
    _logger.debug(
      'Loading more estimations for stream: $streamKey, '
      'limit: $visibleLimit',
    );
    return _watchLocalEstimations(
      streamKey,
      projectId,
      sortBy,
      ascending,
      visibleLimit,
    );
  }

  // TODO: [CA-1424] [Estimation] List the estimates of all projects, not one project id.
  // https://ripplearc.youtrack.cloud/issue/CA-1424
  Future<Either<Failure, List<CostEstimate>>> _watchLocalEstimations(
    String streamKey,
    String projectId,
    EstimationSortOption sortBy,
    bool ascending,
    int visibleLimit,
  ) {
    _releaseWaitingCaller(streamKey);
    final firstResult = Completer<Either<Failure, List<CostEstimate>>>();
    _firstResults[streamKey] = firstResult;

    void publish(Either<Failure, List<CostEstimate>> result) {
      _emitToStream(streamKey, result);
      if (!firstResult.isCompleted) firstResult.complete(result);
      if (!_streamControllers.containsKey(streamKey)) {
        _localSubscriptions.remove(streamKey)?.cancel();
      }
    }

    _localSubscriptions.remove(streamKey)?.cancel();
    _localSubscriptions[streamKey] = _localDataSource
        .watchEstimations(
          projectId: projectId,
          sortBy: sortBy,
          ascending: ascending,
          limit: visibleLimit,
        )
        .listen(
          (dtos) {
            final List<CostEstimate> localEstimates;
            try {
              localEstimates = dtos.map((dto) => dto.toDomain()).toList();
            } catch (e) {
              publish(
                Left(
                  _handleError(
                    e,
                    'reading estimations from the phone',
                    projectId: projectId,
                  ),
                ),
              );
              return;
            }
            // TODO: [CA-1374] [Estimation] Treat rows before the first sync as loading, not as the full list.
            // https://ripplearc.youtrack.cloud/issue/CA-1374
            final hasMore = localEstimates.length >= visibleLimit;
            _paginationStates[streamKey] = PaginationState(
              pageSize: _paginationStates[streamKey]?.pageSize ?? visibleLimit,
              hasMore: hasMore,
            );
            publish(Right(localEstimates));
          },
          onError: (Object error) {
            publish(
              Left(
                _handleError(
                  error,
                  'watching estimations',
                  projectId: projectId,
                ),
              ),
            );
          },
        );
    return firstResult.future;
  }

  void _releaseWaitingCaller(String streamKey) {
    final waiting = _firstResults.remove(streamKey);
    if (waiting != null && !waiting.isCompleted) {
      waiting.complete(Right(_cachedEstimations[streamKey] ?? []));
    }
  }

  @override
  bool hasMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) {
    final streamKey = _buildStreamKey(projectId, sortBy, ascending, limit);
    return _paginationStates[streamKey]?.hasMore ?? true;
  }

  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) {
    final streamKey = _buildStreamKey(projectId, sortBy, ascending, limit);
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
              _visibleLimits.remove(streamKey);
              _localSubscriptions.remove(streamKey)?.cancel();
              _releaseWaitingCaller(streamKey);
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

  @override
  Future<Either<Failure, CostEstimate>> createEstimation(
    CostEstimate estimation,
  ) async {
    try {
      _logger.debug('Creating cost estimation: ${estimation.id}');

      final storedDto = await _localDataSource.insertEstimationRow(
        CostEstimateDto.fromDomain(estimation),
      );

      final createdEstimation = storedDto.toDomain();

      _logger.debug(
        'Successfully created cost estimation: ${createdEstimation.id}',
      );

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

  @override
  void dispose() {
    _logger.debug('Disposing repository and cleaning up resources');

    for (final controller in _streamControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }

    for (final subscription in _localSubscriptions.values) {
      subscription.cancel();
    }
    _firstResults.keys.toList().forEach(_releaseWaitingCaller);

    _streamControllers.clear();
    _cachedEstimations.clear();
    _paginationStates.clear();
    _visibleLimits.clear();
    _localSubscriptions.clear();
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

      await _localDataSource.deleteEstimationRowById(estimationId);

      _logger.debug(
        'Successfully deleted cost estimation: Estimation id: $estimationId, Project id: $projectId',
      );
      return const Right(null);
    } catch (e) {
      return Left(
        _handleError(
          e,
          'deleting cost estimation',
          estimationId: estimationId,
          projectId: projectId,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CostEstimate>> changeLockStatus({
    required String estimationId,
    required bool isLocked,
    required String projectId,
  }) async {
    try {
      _logger.debug(
        'Changing lock status for estimation: $estimationId to $isLocked',
      );

      final lockedDto = await _localDataSource.updateEstimationLockById(
        id: estimationId,
        isLocked: isLocked,
      );
      if (lockedDto == null) {
        _logger.warning('Estimation to lock not on the phone: $estimationId');
        return Left(
          EstimationFailure(errorType: EstimationErrorType.notFoundError),
        );
      }

      return Right(lockedDto.toDomain());
    } catch (e) {
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
  Future<Either<Failure, CostEstimate>> getEstimation(
    String estimationId,
  ) async {
    try {
      final phoneDto = await _localDataSource.loadEstimationById(estimationId);
      final dto = phoneDto ?? await _dataSource.getEstimationById(estimationId);
      if (dto == null) {
        _logger.warning('Estimation not found: $estimationId');
        return Left(
          EstimationFailure(errorType: EstimationErrorType.notFoundError),
        );
      }
      return Right(dto.toDomain());
    } catch (e) {
      return Left(
        _handleError(e, 'getting estimation', estimationId: estimationId),
      );
    }
  }

  // TODO: [CA-1452] A rename moves the last edited date on the server, but the storyboard says it changes only the name.
  // https://ripplearc.youtrack.cloud/issue/CA-1452
  @override
  Future<Either<Failure, CostEstimate>> renameEstimation({
    required String estimationId,
    required String newName,
    required String projectId,
  }) async {
    try {
      _logger.debug('Renaming estimation: $estimationId to $newName');

      final renamedDto = await _localDataSource.updateEstimationNameById(
        id: estimationId,
        newName: newName,
      );
      if (renamedDto == null) {
        _logger.warning('Estimation to rename not on the phone: $estimationId');
        return Left(
          EstimationFailure(errorType: EstimationErrorType.notFoundError),
        );
      }

      return Right(renamedDto.toDomain());
    } catch (e) {
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
