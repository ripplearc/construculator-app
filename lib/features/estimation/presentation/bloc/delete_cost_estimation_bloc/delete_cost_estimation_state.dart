// coverage:ignore-file

part of 'delete_cost_estimation_bloc.dart';

/// Abstract class for delete cost estimation states.
///
/// All states in the delete cost estimation bloc must extend this class.
/// This provides a common interface for state management and ensures
/// proper equality comparison through Equatable.
abstract class DeleteCostEstimationState extends Equatable {
  const DeleteCostEstimationState();
}

/// Initial state when the bloc is first created
class DeleteCostEstimationInitial extends DeleteCostEstimationState {
  const DeleteCostEstimationInitial();

  @override
  List<Object?> get props => [];
}

/// State when the cost estimation deletion is in progress
class DeleteCostEstimationInProgress extends DeleteCostEstimationState {
  const DeleteCostEstimationInProgress();

  @override
  List<Object?> get props => [];
}

/// State when the cost estimation deletion is successful
class DeleteCostEstimationSuccess extends DeleteCostEstimationState {
  final String estimationId;

  const DeleteCostEstimationSuccess({required this.estimationId});

  @override
  List<Object?> get props => [estimationId];
}

/// State when the cost estimation deletion fails
class DeleteCostEstimationFailure extends DeleteCostEstimationState {
  final Failure failure;

  const DeleteCostEstimationFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
