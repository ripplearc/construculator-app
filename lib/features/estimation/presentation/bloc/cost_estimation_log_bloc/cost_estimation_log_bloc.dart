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
/// - Loading more logs with pagination
/// - Error handling and state management
/// - Event concurrency via transformers (restartable for FetchInitial)
class CostEstimationLogBloc
    extends Bloc<CostEstimationLogEvent, CostEstimationLogState> {
  final CostEstimationLogRepository _repository;
  String? _currentEstimateId;
  CancelableOperation<Either<Failure, List<CostEstimationLog>>>?
  _inFlightLoadMore;

  CostEstimationLogBloc({required CostEstimationLogRepository repository})
    : _repository = repository,
      super(const CostEstimationLogInitial()) {
    on<CostEstimationLogFetchInitial>(_onFetchInitial);
    on<CostEstimationLogLoadMore>(_onLoadMore);
  }

  Future<void> _onFetchInitial(
    CostEstimationLogFetchInitial event,
    Emitter<CostEstimationLogState> emit,
  ) async {
    _currentEstimateId = event.estimateId;
    await _inFlightLoadMore?.cancel();
    _inFlightLoadMore = null;

    emit(const CostEstimationLogLoading());

    final result = await _repository.fetchInitialLogs(event.estimateId);

    result.fold((failure) => emit(CostEstimationLogError(failure: failure)), (
      logs,
    ) {
      if (logs.isEmpty) {
        emit(const CostEstimationLogEmpty());
      } else {
        final hasMore = _repository.hasMoreLogs(event.estimateId);
        emit(CostEstimationLogLoaded(logs: logs, hasMore: hasMore));
      }
    });
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

    if (currentState.isLoadingMore || !currentState.hasMore) {
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
