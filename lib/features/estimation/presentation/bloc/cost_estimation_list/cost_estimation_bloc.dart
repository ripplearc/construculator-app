import 'package:construculator/features/estimation/domain/usecases/get_cost_estimation_dashboard_usecase.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list/cost_estimation_events.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list/cost_estimation_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CostEstimationListBloc
    extends Bloc<CostEstimationListEvent, CostEstimationListState> {
  final GetCostEstimationDashboardUseCase getEstimationsUseCase;
  CostEstimationListBloc({required this.getEstimationsUseCase})
    : super(CostEstimationListLoading()) {
    on<LoadCostEstimations>((event, emit) async {});
  }
}
