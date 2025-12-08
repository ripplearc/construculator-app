part of 'add_cost_estimation_bloc.dart';

/// Abstract class for add cost estimation states.
/// 
/// All states in the add cost estimation bloc must extend this class.
/// This provides a common interface for state management and ensures
/// proper equality comparison through Equatable.
abstract class AddCostEstimationState extends Equatable {
  const AddCostEstimationState();
}

/// Initial state when the bloc is first created
class AddCostEstimationInitial extends AddCostEstimationState {
  const AddCostEstimationInitial();

  @override
  List<Object?> get props => [];
}

/// State when the cost estimation creation is in progress
class AddCostEstimationInProgress extends AddCostEstimationState {
  const AddCostEstimationInProgress();

  @override
  List<Object?> get props => [];
}

/// State when the cost estimation creation is successful
class AddCostEstimationSuccess extends AddCostEstimationState {
  final CostEstimate costEstimation;
  
  const AddCostEstimationSuccess({required this.costEstimation});

  @override
  List<Object?> get props => [costEstimation];
}

/// State when the cost estimation creation fails
class AddCostEstimationFailure extends AddCostEstimationState {
  final String message;
  
  const AddCostEstimationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
