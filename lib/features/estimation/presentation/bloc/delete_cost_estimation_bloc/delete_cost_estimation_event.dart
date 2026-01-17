// coverage:ignore-file

part of 'delete_cost_estimation_bloc.dart';

/// Abstract class for delete cost estimation events.
///
/// All events in the delete cost estimation bloc must extend this class.
/// This provides a common interface for event handling and ensures
/// proper equality comparison through Equatable.
abstract class DeleteCostEstimationEvent extends Equatable {
  const DeleteCostEstimationEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object?> get props => [];
}

/// Triggered when the user requests to delete a cost estimation
class DeleteCostEstimationRequested extends DeleteCostEstimationEvent {
  final String estimationId;
  final String projectId;

  const DeleteCostEstimationRequested({
    required this.estimationId,
    required this.projectId,
  });

  @override
  List<Object?> get props => [estimationId, projectId];
}
