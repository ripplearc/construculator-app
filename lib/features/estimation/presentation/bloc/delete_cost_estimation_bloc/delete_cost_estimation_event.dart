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

/// Triggered when the delete cost estimation bloc is initialized
class DeleteCostEstimationStarted extends DeleteCostEstimationEvent {
  const DeleteCostEstimationStarted();
}

/// Triggered when the user requests to delete a cost estimation
class DeleteCostEstimationRequested extends DeleteCostEstimationEvent {
  final String estimationId;

  const DeleteCostEstimationRequested({required this.estimationId});

  @override
  List<Object?> get props => [estimationId];
}
