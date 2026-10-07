import 'dart:collection';

import 'package:async/async.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_log_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cost_estimation_log_event.dart';
part 'cost_estimation_log_state.dart';

/// BLoC for managing cost estimation activity logs with pagination support.
///
/// This BLoC handles:
/// - Fetching initial logs for an estimation
/// - Reloading on pull-down while the loaded logs stay on screen
/// - Loading more logs with pagination
/// - Error handling and state management
/// - Event concurrency via transformers (restartable for FetchInitial)
///
/// Whether the last first load failed is kept in a field, not read back from
/// [state]: a second tap on Try again can start after the first retry has
/// already emitted Loading, and the second failure must still read "Still
/// couldn't load Logs."
class CostEstimationLogBloc
    extends Bloc<CostEstimationLogEvent, CostEstimationLogState> {
  final CostEstimationLogRepository _repository;
  String? _currentEstimateId;
  CancelableOperation<Either<Failure, List<CostEstimationLog>>>?
  _inFlightLoadMore;
  bool _lastFirstLoadFailed = false;

  CostEstimationLogBloc({required this._repository})
    : super(const CostEstimationLogInitial()) {
    on<CostEstimationLogFetchInitial>(_onFetchInitial);
    on<CostEstimationLogRefresh>(_onRefresh);
    on<CostEstimationLogLoadMore>(_onLoadMore);
  }

  Future<void> _onFetchInitial(
    CostEstimationLogFetchInitial event,
    Emitter<CostEstimationLogState> emit,
  ) async {
    _currentEstimateId = event.estimateId;
    await _inFlightLoadMore?.cancel();
    _inFlightLoadMore = null;

    final isRetryAfterFailure = _lastFirstLoadFailed;
    emit(const CostEstimationLogLoading());

    final result = await _repository.fetchInitialLogs(event.estimateId);

    _lastFirstLoadFailed = result.isLeft();
    result.fold(
      (failure) => emit(
        CostEstimationLogError(
          failure: failure,
          isRepeatFailure: isRetryAfterFailure,
        ),
      ),
      (logs) => _emitFirstPage(logs, event.estimateId, emit),
    );
  }

  // Reloads the first page without passing through Loading, so the logs on
  // screen stay put while it runs and after it fails (CUJ 11 screen 13).
  // With nothing on screen to keep, it is a first load.
  Future<void> _onRefresh(
    CostEstimationLogRefresh event,
    Emitter<CostEstimationLogState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CostEstimationLogWithData) {
      return _onFetchInitial(
        CostEstimationLogFetchInitial(estimateId: event.estimateId),
        emit,
      );
    }

    _currentEstimateId = event.estimateId;
    await _inFlightLoadMore?.cancel();
    _inFlightLoadMore = null;

    emit(
      CostEstimationLogLoaded(
        logs: currentState.logs.toList(),
        hasMore: currentState.hasMore,
        isRefreshing: true,
      ),
    );

    final result = await _repository.fetchInitialLogs(event.estimateId);

    result.fold(
      (_) => emit(
        CostEstimationLogLoaded(
          logs: currentState.logs.toList(),
          hasMore: currentState.hasMore,
          hasRefreshFailed: true,
        ),
      ),
      (logs) => _emitFirstPage(logs, event.estimateId, emit),
    );
  }

  void _emitFirstPage(
    List<CostEstimationLog> logs,
    String estimateId,
    Emitter<CostEstimationLogState> emit,
  ) {
    if (logs.isEmpty) {
      emit(const CostEstimationLogEmpty());
    } else {
      final hasMore = _repository.hasMoreLogs(estimateId);
      emit(CostEstimationLogLoaded(logs: logs, hasMore: hasMore));
    }
  }

  Future<void> _onLoadMore(
    CostEstimationLogLoadMore event,
    Emitter<CostEstimationLogState> emit,
  ) async {
    final currentState = state;

    if (currentState is! CostEstimationLogWithData) {
      return;
    }

    if (_currentEstimateId != event.estimateId) {
      return;
    }

    if (currentState.isLoadingMore ||
        currentState.isRefreshing ||
        !currentState.hasMore) {
      return;
    }

    emit(
      CostEstimationLogLoaded(
        logs: currentState.logs.toList(),
        hasMore: currentState.hasMore,
        isLoadingMore: true,
      ),
    );

    final operation =
        CancelableOperation<
          Either<Failure, List<CostEstimationLog>>
        >.fromFuture(_repository.loadMoreLogs(event.estimateId));

    _inFlightLoadMore = operation;

    final result = await operation.valueOrCancellation();
    if (result == null) {
      return;
    }

    _inFlightLoadMore = null;

    result.fold(
      (failure) => emit(
        CostEstimationLogLoadMoreError(
          failure: failure,
          logs: currentState.logs.toList(),
          isRepeatFailure: currentState is CostEstimationLogLoadMoreError,
          hasMore: currentState.hasMore,
        ),
      ),
      (newLogs) {
        final allLogs = [...currentState.logs, ...newLogs];
        final hasMore = _repository.hasMoreLogs(event.estimateId);
        emit(
          CostEstimationLogLoaded(
            logs: allLogs,
            hasMore: hasMore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    _currentEstimateId = null;
    await _inFlightLoadMore?.cancel();
    return super.close();
  }
}
