import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/powersync_cost_estimation_data_source.dart';
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

/// Implementation of [CostEstimationRepository] that reads the list from the
/// phone's PowerSync copy and writes through Supabase.
///
/// Isolates reactive estimation streams, pagination state, and cache
/// by a composite key of `projectId + sortBy + limit`, so multiple
/// query contexts for the same project do not share state. Paging raises the
/// limit of the local watch instead of fetching offsets.
///
/// A write reaches the phone's copy only after the next sync, so a local
/// re-emission in between would show the old value. Until saves go through the
/// phone, each write to a watched project is remembered as a pending edit and
/// re-applied to every list that arrives from the local watch, until a list
/// shows the change or nobody watches the project any more.
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

  // TODO: [CA-1289] [Estimation] Remove pending edits once saves go through the phone.
  // https://ripplearc.youtrack.cloud/issue/CA-1289
  final Map<String, _PendingEdit> _pendingEdits = {};

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
            final localEstimates = dtos.map((dto) => dto.toDomain()).toList();
            // TODO: [CA-1374] [Estimation] Treat rows before the first sync as loading, not as the full list.
            // https://ripplearc.youtrack.cloud/issue/CA-1374
            final hasMore = localEstimates.length >= visibleLimit;
            _paginationStates[streamKey] = PaginationState(
              pageSize: _paginationStates[streamKey]?.pageSize ?? visibleLimit,
              hasMore: hasMore,
            );
            publish(Right(_applyPendingEdits(projectId, localEstimates)));
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

  List<CostEstimate> _applyPendingEdits(
    String projectId,
    List<CostEstimate> localEstimates,
  ) {
    _pendingEdits.removeWhere(
      (_, edit) =>
          edit.projectId == projectId && edit.isReflected(localEstimates),
    );
    return _pendingEdits.values
        .where((edit) => edit.projectId == projectId)
        .fold(localEstimates, (estimates, edit) => edit.apply(estimates));
  }

  bool _isWatched(String projectId) =>
      _streamControllers.keys.any((key) => key.startsWith('$projectId:'));

  void _forgetPendingEditsWhenUnwatched(String projectId) {
    if (!_isWatched(projectId)) {
      _pendingEdits.removeWhere((_, edit) => edit.projectId == projectId);
    }
  }

  void _rememberPendingEdit(
    String editKey,
    String projectId, {
    required List<CostEstimate> Function(List<CostEstimate>) apply,
    required bool Function(List<CostEstimate>) isReflected,
  }) {
    if (!_isWatched(projectId)) return;
    _pendingEdits[editKey] = (
      projectId: projectId,
      apply: apply,
      isReflected: isReflected,
    );
  }

  void _rememberServerVersion(
    String editKey,
    String projectId,
    CostEstimate serverVersion, {
    required CostEstimate Function(CostEstimate) patch,
    required bool Function(CostEstimate) isReflected,
  }) {
    _rememberPendingEdit(
      editKey,
      projectId,
      apply: (estimates) =>
          _replaceEstimation(estimates, serverVersion.id, patch),
      isReflected: (estimates) =>
          estimates.any((e) => e.id == serverVersion.id && isReflected(e)),
    );
  }

  List<CostEstimate> _replaceEstimation(
    List<CostEstimate> estimates,
    String estimationId,
    CostEstimate Function(CostEstimate) replace,
  ) {
    return estimates.map((e) => e.id == estimationId ? replace(e) : e).toList();
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
              _forgetPendingEditsWhenUnwatched(projectId);
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

  Map<String, List<CostEstimate>> _cachedListsOfProject(String projectId) => {
    for (final key in _streamControllers.keys.where(
      (k) => k.startsWith('$projectId:'),
    ))
      key: _cachedEstimations[key] ?? [],
  };

  void _restoreCachedLists(Map<String, List<CostEstimate>> lists) {
    lists.forEach((key, estimates) => _emitToStream(key, Right(estimates)));
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

    return null;
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

      _rememberPendingEdit(
        'create:${createdEstimation.id}',
        estimation.projectId,
        apply: (estimates) => estimates.any((e) => e.id == createdEstimation.id)
            ? estimates
            : [createdEstimation, ...estimates],
        isReflected: (estimates) =>
            estimates.any((e) => e.id == createdEstimation.id),
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

      final updatedEstimations =
          cachedEstimations.any((e) => e.id == newEstimation.id)
          ? cachedEstimations
          : [newEstimation, ...cachedEstimations];

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

    for (final subscription in _localSubscriptions.values) {
      subscription.cancel();
    }
    _firstResults.keys.toList().forEach(_releaseWaitingCaller);

    _streamControllers.clear();
    _cachedEstimations.clear();
    _paginationStates.clear();
    _visibleLimits.clear();
    _localSubscriptions.clear();
    _pendingEdits.clear();
  }

  @override
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  ) async {
    final originalLists = _cachedListsOfProject(projectId);

    try {
      _logger.debug(
        'Deleting cost estimation: Estimation id: $estimationId, Project id: $projectId',
      );

      _rememberPendingEdit(
        'delete:$estimationId',
        projectId,
        apply: (estimates) =>
            estimates.where((e) => e.id != estimationId).toList(),
        isReflected: (estimates) =>
            estimates.every((e) => e.id != estimationId),
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

      _pendingEdits.remove('delete:$estimationId');
      _restoreCachedLists(originalLists);

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
    final lockEdit = 'lock:$estimationId';

    try {
      _logger.debug(
        'Changing lock status for estimation: $estimationId to $isLocked',
      );

      final optimisticLockStatus = isLocked
          ? LockStatus.locked()
          : LockStatus.unlocked();
      _rememberPendingEdit(
        lockEdit,
        projectId,
        apply: (estimates) => _replaceEstimation(
          estimates,
          estimationId,
          (e) => e.copyWith(lockStatus: optimisticLockStatus),
        ),
        isReflected: (estimates) => estimates.any(
          (e) => e.id == estimationId && e.lockStatus.isLocked == isLocked,
        ),
      );
      _emitOptimisticUpdate(
        projectId: projectId,
        estimationId: estimationId,
        updateFn: (e) => e.copyWith(lockStatus: optimisticLockStatus),
      );

      final updatedDto = await _dataSource.changeLockStatus(
        estimationId: estimationId,
        isLocked: isLocked,
      );

      final updatedEstimation = updatedDto.toDomain();

      _rememberServerVersion(
        lockEdit,
        projectId,
        updatedEstimation,
        patch: (e) => e.copyWith(lockStatus: updatedEstimation.lockStatus),
        isReflected: (e) => e.lockStatus.isLocked == isLocked,
      );
      _finalizeOptimisticUpdate(projectId, estimationId, updatedEstimation);

      return Right(updatedEstimation);
    } catch (e) {
      _pendingEdits.remove(lockEdit);
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
  Future<Either<Failure, CostEstimate>> getEstimation(
    String estimationId,
  ) async {
    try {
      final dto = await _dataSource.getEstimationById(estimationId);
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

  @override
  Future<Either<Failure, CostEstimate>> renameEstimation({
    required String estimationId,
    required String newName,
    required String projectId,
  }) async {
    final originalEstimation = _getOriginalEstimation(projectId, estimationId);
    final renameEdit = 'rename:$estimationId';

    try {
      _logger.debug('Renaming estimation: $estimationId to $newName');

      _rememberPendingEdit(
        renameEdit,
        projectId,
        apply: (estimates) => _replaceEstimation(
          estimates,
          estimationId,
          (e) => e.copyWith(estimateName: newName),
        ),
        isReflected: (estimates) => estimates.any(
          (e) => e.id == estimationId && e.estimateName == newName,
        ),
      );
      _emitOptimisticUpdate(
        projectId: projectId,
        estimationId: estimationId,
        updateFn: (e) => e.copyWith(estimateName: newName),
      );

      final updatedDto = await _dataSource.renameEstimation(
        estimationId: estimationId,
        newName: newName,
      );

      final updatedEstimationFromRemote = updatedDto.toDomain();
      final updatedEstimation = updatedEstimationFromRemote.copyWith(
        updatedAt:
            originalEstimation?.updatedAt ??
            updatedEstimationFromRemote.updatedAt,
      );

      _rememberServerVersion(
        renameEdit,
        projectId,
        updatedEstimation,
        patch: (e) => e.copyWith(
          estimateName: updatedEstimation.estimateName,
          updatedAt: updatedEstimation.updatedAt,
        ),
        isReflected: (e) => e.estimateName == newName,
      );
      _finalizeOptimisticUpdate(projectId, estimationId, updatedEstimation);

      return Right(updatedEstimation);
    } catch (e) {
      _pendingEdits.remove(renameEdit);
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

typedef _PendingEdit = ({
  String projectId,
  List<CostEstimate> Function(List<CostEstimate>) apply,
  bool Function(List<CostEstimate>) isReflected,
});
