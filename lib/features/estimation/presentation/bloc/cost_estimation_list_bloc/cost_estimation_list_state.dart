part of 'cost_estimation_list_bloc.dart';

/// Abstract class for cost estimation list states.
abstract class CostEstimationListState extends Equatable {
  const CostEstimationListState();
}

/// Initial state when the bloc is first created
class CostEstimationListInitial extends CostEstimationListState {
  const CostEstimationListInitial();

  @override
  List<Object?> get props => [];
}

/// State when the cost estimations are being loaded
class CostEstimationListLoading extends CostEstimationListState {
  const CostEstimationListLoading();

  @override
  List<Object?> get props => [];
}

/// State when the cost estimations are loaded successfully but the list is empty
class CostEstimationListEmpty extends CostEstimationListState {
  const CostEstimationListEmpty();

  @override
  List<Object?> get props => [];
}

/// Abstract base class for states that can contain cost estimation data.
abstract class CostEstimationListWithData extends CostEstimationListState {
  /// The list of cost estimations
  final List<CostEstimate> estimates;

  const CostEstimationListWithData({required this.estimates});

  /// List of properties that will be used to compare states
  @override
  List<Object?> get props => [estimates];
}

/// State when loading cost estimations fails but we have previous data
class CostEstimationListError extends CostEstimationListWithData {
  /// The error message describing what went wrong
  final Failure failure;

  const CostEstimationListError({
    required this.failure,
    required super.estimates,
  });

  @override
  List<Object?> get props => [failure, estimates];
}

/// State when the cost estimations are loaded successfully with data
class CostEstimationListLoaded extends CostEstimationListWithData {
  const CostEstimationListLoaded({required super.estimates});

  @override
  List<Object?> get props => [estimates];
}
