// coverage:ignore-file

part of 'cost_estimation_log_bloc.dart';

/// Abstract class for cost estimation log events.
abstract class CostEstimationLogEvent extends Equatable {
  const CostEstimationLogEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered to fetch the initial page of logs for an estimation
class CostEstimationLogFetchInitial extends CostEstimationLogEvent {
  final String estimateId;

  const CostEstimationLogFetchInitial({required this.estimateId});

  @override
  List<Object?> get props => [estimateId];
}

/// Triggered by a pull-down to load the first page again, keeping the logs
/// already on screen until the new page arrives
class CostEstimationLogRefresh extends CostEstimationLogEvent {
  final String estimateId;

  const CostEstimationLogRefresh({required this.estimateId});

  @override
  List<Object?> get props => [estimateId];
}

/// Triggered to load the next page of logs for an estimation
class CostEstimationLogLoadMore extends CostEstimationLogEvent {
  final String estimateId;

  const CostEstimationLogLoadMore({required this.estimateId});

  @override
  List<Object?> get props => [estimateId];
}
