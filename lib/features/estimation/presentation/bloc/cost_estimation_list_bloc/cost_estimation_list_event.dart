// coverage:ignore-file

part of 'cost_estimation_list_bloc.dart';

/// Abstract class for cost estimation list events.
abstract class CostEstimationListEvent extends Equatable {
  const CostEstimationListEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object?> get props => [];
}

/// Triggered to start watching estimations for a project
class CostEstimationListStartWatching extends CostEstimationListEvent {
  final String projectId;
  const CostEstimationListStartWatching({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}

/// Triggered to load the next page of estimations
class CostEstimationListLoadMore extends CostEstimationListEvent {
  final String projectId;
  const CostEstimationListLoadMore({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}

/// Refreshes the list of estimations for a project after a pull-to-refresh action
class CostEstimationListRefresh extends CostEstimationListEvent {
  final String projectId;
  const CostEstimationListRefresh({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}

/// Triggered when the stream emits new result (either success or failure)
class _CostEstimationListUpdated extends CostEstimationListEvent {
  final Either<Failure, List<CostEstimate>> result;
  final bool hasMore;
  const _CostEstimationListUpdated(this.result, {this.hasMore = true});

  @override
  List<Object?> get props => [result, hasMore];
}
