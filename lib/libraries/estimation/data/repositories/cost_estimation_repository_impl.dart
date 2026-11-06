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
/// phone, each write is remembered as a pending edit and re-applied to every
/// list that arrives from the local watch. An edit is dropped once each list
/// that held the row shows the change, so it survives a screen being closed
/// and reopened before the sync.
class CostEstimationRepositoryImpl implements CostEstimationRepository {
  final CostEstimationDataSource _dataSource;
  final PowerSyncCostEstimationDataSource _localDataSource;
  static final _logger = AppLogger().tag('CostEstimationRepositoryImpl');

  final Map<String, StreamController<Either<Failure, List<CostEstimate>>>>
  _streamControllers = {};
  final Map<String, List<CostEstimate>> _cachedEstimations = {};
  final Map<String, PaginationState> _paginationStates = {};
  final Map<String, int> _visibleLimits = {};
  final Map<String, _PhoneCopy> _phoneCopies = {};
  int _editCount = 0;
  final Map<String, StreamSubscription<List<CostEstimateDto>>>
  _localSubscriptions = {};
  final Map<String, Completer<Either<Failure, List<CostEstimate>>>>
  _firstResults = {};

  // TODO: [CA-1423] [Estimation] Remove pending edits once saves go through the phone.
  // https://ripplearc.youtrack.cloud/issue/CA-1423
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
    final view = (sortBy: sortBy, ascending: ascending, limit: visibleLimit);
    for (final edit in _pendingEditsOf(projectId)) {
      edit.awaitingKeys.add(streamKey);
    }

    void publish(Either<Failure, List<CostEstimate>> result) {
      _emitToStream(streamKey, result);
      if (!firstResult.isCompleted) firstResult.complete(result);
      if (!_streamControllers.containsKey(streamKey)) {
        _localSubscriptions.remove(streamKey)?.cancel();
        _forgetStream(streamKey);
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
              _phoneCopies.remove(streamKey);
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
            publish(
              Right(
                _applyPendingEdits(streamKey, projectId, localEstimates, view),
              ),
            );
          },
          onError: (Object error) {
            _phoneCopies.remove(streamKey);
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
    String streamKey,
    String projectId,
    List<CostEstimate> estimates,
    _ListView view,
  ) {
    _phoneCopies[streamKey] = (estimates: estimates, view: view);
    var shown = estimates;
    for (final edit in _pendingEditsOf(projectId)) {
      if (_isReflectedOn(edit, estimates, view)) {
        if (edit.awaitingKeys.remove(streamKey)) edit.wasReflected = true;
      } else {
        shown = edit.apply(shown, view);
      }
    }
    _dropSettledEdits();
    return shown;
  }

  Iterable<_PendingEdit> _pendingEditsOf(String projectId) => _pendingEdits
      .values
      .where((edit) => edit.projectId == projectId)
      .toList();

  Iterable<String> _watchedKeysOf(String projectId) =>
      _streamControllers.keys.where((key) => key.startsWith('$projectId:'));

  void _dropSettledEdits() => _pendingEdits.removeWhere(
    (_, edit) => edit.wasReflected && edit.awaitingKeys.isEmpty,
  );

  void _forgetStream(String streamKey) {
    _phoneCopies.remove(streamKey);
    for (final edit in _pendingEdits.values) {
      edit.awaitingKeys.remove(streamKey);
    }
    _dropSettledEdits();
  }

  bool _isSettledOnEveryWatchedList(String projectId, _PendingEdit edit) =>
      edit.awaitingKeys.isEmpty && _watchedKeysOf(projectId).isNotEmpty;

  _PendingEdit _rememberPendingEdit(
    String editKey,
    String projectId, {
    required _Apply apply,
    required _IsReflected isReflected,
    String? estimationId,
  }) {
    // ignore: no_direct_instantiation, reason: file-private value holder, not a service
    final edit = _PendingEdit(
      projectId: projectId,
      apply: apply,
      isReflected: isReflected,
      estimationId: estimationId,
    );
    for (final key in _watchedKeysOf(projectId)) {
      final copy = _phoneCopies[key];
      if (copy == null || !_isReflectedOn(edit, copy.estimates, copy.view)) {
        edit.awaitingKeys.add(key);
      }
    }
    if (_isSettledOnEveryWatchedList(projectId, edit)) {
      edit.wasReflected = true;
    }
    _pendingEdits[editKey] = edit;
    return edit;
  }

  bool _isReflectedOn(
    _PendingEdit edit,
    List<CostEstimate> estimates,
    _ListView view,
  ) {
    final estimationId = edit.estimationId;
    final rowIsStillBeingCreated =
        estimationId != null &&
        _pendingEdits.containsKey('create:$estimationId') &&
        estimates.every((e) => e.id != estimationId);
    return !rowIsStillBeingCreated && edit.isReflected(estimates, view);
  }

  String _newEditKey(String kind, String estimationId) =>
      '$kind:$estimationId:${_editCount++}';

  void _forgetPendingEdit(String editKey) => _pendingEdits.remove(editKey);

  void _rememberServerVersion(
    _PendingEdit edit, {
    required String estimationId,
    required DateTime writtenAt,
    required CostEstimate Function(CostEstimate) patch,
    required bool Function(CostEstimate) showsWrite,
  }) {
    edit.apply = (estimates, _) =>
        _replaceEstimation(estimates, estimationId, patch);
    edit.isReflected = _rowReflects(estimationId, showsWrite, writtenAt);
  }

  _IsReflected _rowReflects(
    String estimationId,
    bool Function(CostEstimate) showsWrite, [
    DateTime? writtenAt,
  ]) {
    return (estimates, _) => estimates.every(
      (e) =>
          e.id != estimationId ||
          showsWrite(e) ||
          (writtenAt != null && e.updatedAt.isAfter(writtenAt)),
    );
  }

  void _republishProject(String projectId) {
    for (final key in _watchedKeysOf(projectId).toList()) {
      final copy = _phoneCopies[key];
      if (copy == null) continue;
      _emitToStream(
        key,
        Right(_applyPendingEdits(key, projectId, copy.estimates, copy.view)),
      );
    }
  }

  List<CostEstimate> _replaceEstimation(
    List<CostEstimate> estimates,
    String estimationId,
    CostEstimate Function(CostEstimate) replace,
  ) {
    return estimates.map((e) => e.id == estimationId ? replace(e) : e).toList();
  }

  List<CostEstimate> _withCreated(
    List<CostEstimate> estimates,
    CostEstimate created,
    _ListView view,
  ) {
    final position = estimates.indexWhere(
      (e) => _sortsBefore(created, e, view),
    );
    final merged = [...estimates]
      ..insert(position == -1 ? estimates.length : position, created);
    return merged.take(view.limit).toList();
  }

  bool _sortsBefore(CostEstimate a, CostEstimate b, _ListView view) {
    final byUpdatedAt = view.sortBy == EstimationSortOption.updatedAt;
    final aTime = byUpdatedAt ? a.updatedAt : a.createdAt;
    final bTime = byUpdatedAt ? b.updatedAt : b.createdAt;
    return view.ascending ? aTime.isBefore(bTime) : !aTime.isBefore(bTime);
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
              _forgetStream(streamKey);
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

    return null;
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
        apply: (estimates, view) =>
            _withCreated(estimates, createdEstimation, view),
        isReflected: (estimates, view) =>
            estimates.any((e) => e.id == createdEstimation.id) ||
            !_withCreated(
              estimates,
              createdEstimation,
              view,
            ).any((e) => e.id == createdEstimation.id),
      );
      _republishProject(estimation.projectId);

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
    _phoneCopies.clear();
    _pendingEdits.clear();
  }

  @override
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  ) async {
    final deleteEdit = _newEditKey('delete', estimationId);
    _rememberPendingEdit(
      deleteEdit,
      projectId,
      estimationId: estimationId,
      apply: (estimates, _) =>
          estimates.where((e) => e.id != estimationId).toList(),
      isReflected: (estimates, _) =>
          estimates.every((e) => e.id != estimationId),
    );
    _republishProject(projectId);

    try {
      _logger.debug(
        'Deleting cost estimation: Estimation id: $estimationId, Project id: $projectId',
      );

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

      _forgetPendingEdit(deleteEdit);
      _republishProject(projectId);

      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, CostEstimate>> changeLockStatus({
    required String estimationId,
    required bool isLocked,
    required String projectId,
  }) async {
    final lockEdit = _newEditKey('lock', estimationId);
    final optimisticLockStatus = isLocked
        ? LockStatus.locked()
        : LockStatus.unlocked();
    bool showsWrite(CostEstimate e) => e.lockStatus.isLocked == isLocked;
    final edit = _rememberPendingEdit(
      lockEdit,
      projectId,
      estimationId: estimationId,
      apply: (estimates, _) => _replaceEstimation(
        estimates,
        estimationId,
        (e) => e.copyWith(lockStatus: optimisticLockStatus),
      ),
      isReflected: _rowReflects(estimationId, showsWrite),
    );
    _republishProject(projectId);

    try {
      _logger.debug(
        'Changing lock status for estimation: $estimationId to $isLocked',
      );

      final updatedDto = await _dataSource.changeLockStatus(
        estimationId: estimationId,
        isLocked: isLocked,
      );

      final updatedEstimation = updatedDto.toDomain();

      _rememberServerVersion(
        edit,
        estimationId: estimationId,
        writtenAt: updatedEstimation.updatedAt,
        patch: (e) => e.copyWith(lockStatus: updatedEstimation.lockStatus),
        showsWrite: showsWrite,
      );
      _republishProject(projectId);

      return Right(updatedEstimation);
    } catch (e) {
      _forgetPendingEdit(lockEdit);
      _republishProject(projectId);
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
    final renameEdit = _newEditKey('rename', estimationId);
    bool showsWrite(CostEstimate e) => e.estimateName == newName;
    final edit = _rememberPendingEdit(
      renameEdit,
      projectId,
      estimationId: estimationId,
      apply: (estimates, _) => _replaceEstimation(
        estimates,
        estimationId,
        (e) => e.copyWith(estimateName: newName),
      ),
      isReflected: _rowReflects(estimationId, showsWrite),
    );
    _republishProject(projectId);

    try {
      _logger.debug('Renaming estimation: $estimationId to $newName');

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
        edit,
        estimationId: estimationId,
        writtenAt: updatedEstimationFromRemote.updatedAt,
        patch: (e) => e.copyWith(
          estimateName: updatedEstimation.estimateName,
          updatedAt: updatedEstimation.updatedAt,
        ),
        showsWrite: showsWrite,
      );
      _republishProject(projectId);

      return Right(updatedEstimation);
    } catch (e) {
      _forgetPendingEdit(renameEdit);
      _republishProject(projectId);
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

typedef _ListView = ({EstimationSortOption sortBy, bool ascending, int limit});

typedef _PhoneCopy = ({List<CostEstimate> estimates, _ListView view});

typedef _Apply = List<CostEstimate> Function(List<CostEstimate>, _ListView);

typedef _IsReflected = bool Function(List<CostEstimate>, _ListView);

class _PendingEdit {
  _PendingEdit({
    required this.projectId,
    required this.apply,
    required this.isReflected,
    this.estimationId,
  });

  final String projectId;
  final String? estimationId;
  final Set<String> awaitingKeys = {};
  _Apply apply;
  _IsReflected isReflected;
  bool wasReflected = false;
}
