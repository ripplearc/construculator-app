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
  const CostEstimationListStartWatching();
}

/// Triggered to load the next page of estimations
class CostEstimationListLoadMore extends CostEstimationListEvent {
  const CostEstimationListLoadMore();
}

/// Refreshes the list of estimations for a project after a pull-to-refresh action
class CostEstimationListRefresh extends CostEstimationListEvent {
  const CostEstimationListRefresh();
}

/// Triggered when the stream emits new result (either success or failure)
class _CostEstimationListUpdated extends CostEstimationListEvent {
  final Either<Failure, List<CostEstimate>> result;
  final bool hasMore;
  const _CostEstimationListUpdated(this.result, {this.hasMore = true});

  @override
  List<Object?> get props => [result, hasMore];
}

class _CostEstimationListProjectUnavailable extends CostEstimationListEvent {
  const _CostEstimationListProjectUnavailable();

  @override
  List<Object?> get props => [];
}
