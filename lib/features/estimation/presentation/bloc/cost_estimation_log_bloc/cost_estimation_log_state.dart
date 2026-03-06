// coverage:ignore-file

part of 'cost_estimation_log_bloc.dart';

/// Abstract class for cost estimation log states.
abstract class CostEstimationLogState extends Equatable {
  const CostEstimationLogState();
}

/// Initial state when the bloc is first created
class CostEstimationLogInitial extends CostEstimationLogState {
  const CostEstimationLogInitial();

  @override
  List<Object?> get props => [];
}

/// State when the logs are being loaded for the first time
class CostEstimationLogLoading extends CostEstimationLogState {
  const CostEstimationLogLoading();

  @override
  List<Object?> get props => [];
}

/// State when the logs are loaded successfully but the list is empty
class CostEstimationLogEmpty extends CostEstimationLogState {
  const CostEstimationLogEmpty();

  @override
  List<Object?> get props => [];
}

/// Abstract base class for states that can contain log data.
abstract class CostEstimationLogWithData extends CostEstimationLogState {
  final UnmodifiableListView<CostEstimationLog> logs;
  final bool hasMore;
  final bool isLoadingMore;

  CostEstimationLogWithData({
    required List<CostEstimationLog> logs,
    this.hasMore = false,
    this.isLoadingMore = false,
  }) : logs = UnmodifiableListView<CostEstimationLog>(
          List<CostEstimationLog>.from(logs),
        );

  @override
  List<Object?> get props => [logs, hasMore, isLoadingMore];
}

/// State when loading logs fails
class CostEstimationLogError extends CostEstimationLogState {
  final Failure failure;

  const CostEstimationLogError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

/// State when loading more logs fails but we have previous data
class CostEstimationLogLoadMoreError extends CostEstimationLogWithData {
  final Failure failure;

  CostEstimationLogLoadMoreError({
    required this.failure,
    required super.logs,
    super.hasMore,
  });

  @override
  List<Object?> get props => [failure, logs, hasMore];
}

/// State when the logs are loaded successfully with data
class CostEstimationLogLoaded extends CostEstimationLogWithData {
  CostEstimationLogLoaded({
    required super.logs,
    super.hasMore,
    super.isLoadingMore,
  });

  CostEstimationLogLoaded copyWith({
    List<CostEstimationLog>? logs,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CostEstimationLogLoaded(
      logs: logs ?? this.logs.toList(),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [logs, hasMore, isLoadingMore];
}
