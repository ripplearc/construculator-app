import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/usecases/get_estimations_usecase.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cost_estimation_list_event.dart';
part 'cost_estimation_list_state.dart';

class CostEstimationListBloc
    extends Bloc<CostEstimationListEvent, CostEstimationListState> {
  final GetEstimationsUseCase _getEstimationsUseCase;

  CostEstimationListBloc({required GetEstimationsUseCase getEstimationsUseCase})
    : _getEstimationsUseCase = getEstimationsUseCase,
      super(const CostEstimationListInitial()) {
    on<CostEstimationListRefreshEvent>(_onRefresh);
  }

  Future<void> _onRefresh(
    CostEstimationListRefreshEvent event,
    Emitter<CostEstimationListState> emit,
  ) async {
    final currentEstimations = state is CostEstimationListWithData
        ? (state as CostEstimationListWithData).estimates
        : <CostEstimate>[];
    emit(const CostEstimationListLoading());
    await _loadEstimations(emit, event.projectId, currentEstimations);
  }

  Future<void> _loadEstimations(
    Emitter<CostEstimationListState> emit,
    String projectId,
    List<CostEstimate> currentEstimations,
  ) async {
    final result = await _getEstimationsUseCase(projectId);

    result.fold(
      (failure) {
        emit(
          CostEstimationListError(
            failure: failure,
            estimates: currentEstimations,
          ),
        );
      },
      (estimations) {
        if (estimations.isEmpty) {
          emit(const CostEstimationListEmpty());
        } else {
          emit(CostEstimationListLoaded(estimates: estimations));
        }
      },
    );
  }
}
