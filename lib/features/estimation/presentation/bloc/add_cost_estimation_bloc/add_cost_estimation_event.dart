// coverage:ignore-file

part of 'add_cost_estimation_bloc.dart';

/// Abstract class for add cost estimation events.
///
/// All events in the add cost estimation bloc must extend this class.
/// This provides a common interface for event handling and ensures
/// proper equality comparison through Equatable.
abstract class AddCostEstimationEvent extends Equatable {
  const AddCostEstimationEvent();

  /// List of properties that will be used to compare events
  @override
  List<Object?> get props => [];
}

/// Triggered when the user submits a new cost estimation creation request
class AddCostEstimationSubmitted extends AddCostEstimationEvent {
  final String estimationName;
  final String projectId;
  final String creatorUserId;

  const AddCostEstimationSubmitted({
    required this.estimationName,
    required this.projectId,
    required this.creatorUserId,
  });

  @override
  List<Object?> get props => [estimationName, projectId, creatorUserId];
}
