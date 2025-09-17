/// Event classes for CostEstimationListBloc
abstract class CostEstimationListEvent {}

class LoadCostEstimations extends CostEstimationListEvent {
  final String projectId;
  LoadCostEstimations(this.projectId);
}

class RefreshCostEstimations extends CostEstimationListEvent {}
