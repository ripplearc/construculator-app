// coverage:ignore-file

part of 'cost_estimation_list_bloc.dart';

/// Abstract class for cost estimation list events.
abstract class CostEstimationListEvent extends Equatable {
  const CostEstimationListEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object?> get props => [];
}

/// Triggered when the user manually requests a refresh of the cost estimations list
class CostEstimationListRefreshEvent extends CostEstimationListEvent {
  final String projectId;
  const CostEstimationListRefreshEvent({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}
