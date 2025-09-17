import 'package:construculator/features/estimation/domain/entities/cost_estimation.dart';

/// State classes for CostEstimationListBloc
abstract class CostEstimationListState {}

class CostEstimationListLoading extends CostEstimationListState {}

class CostEstimationListLoaded extends CostEstimationListState {
  final List<CostEstimation> estimations;
  CostEstimationListLoaded(this.estimations);
}

class CostEstimationListEmpty extends CostEstimationListState {}

class CostEstimationListError extends CostEstimationListState {
  final String message;
  CostEstimationListError(this.message);
}
