import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/usecases/get_estimations_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cost_estimation_list_event.dart';
part 'cost_estimation_list_state.dart';

/// Bloc for managing the cost estimation list state and operations.
/// 
/// This bloc handles loading and refreshing cost estimations for a specific project.
/// It follows the project's naming conventions and patterns for BLoC implementation.
class CostEstimationListBloc extends Bloc<CostEstimationListEvent, CostEstimationListState> {
  final GetEstimationsUseCase _getEstimationsUseCase;
  final String _projectId;

  CostEstimationListBloc({
    required GetEstimationsUseCase getEstimationsUseCase,
    required String projectId,
  }) : _getEstimationsUseCase = getEstimationsUseCase,
       _projectId = projectId,
       super(const CostEstimationListInitial()) {
    on<CostEstimationListRefreshEvent>(_onRefresh);
    add(const CostEstimationListRefreshEvent());
  }

  Future<void> _onRefresh(
    CostEstimationListRefreshEvent event,
    Emitter<CostEstimationListState> emit,
  ) async {
    emit(const CostEstimationListLoading());
    await _loadEstimations(emit);
  }

  Future<void> _loadEstimations(
    Emitter<CostEstimationListState> emit,
  ) async {
    final result = await _getEstimationsUseCase(_projectId);
    
    result.fold(
      (failure) {
        final currentEstimations = state is CostEstimationListWithData
            ? (state as CostEstimationListWithData).estimates
            : <CostEstimate>[];
        
        emit(CostEstimationListError(
          message: 'Failed to load cost estimations',
          estimates: currentEstimations,
        ));
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
