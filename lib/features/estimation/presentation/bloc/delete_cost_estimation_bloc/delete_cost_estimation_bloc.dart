import 'package:construculator/features/estimation/domain/usecases/delete_cost_estimation_usecase.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'delete_cost_estimation_event.dart';
part 'delete_cost_estimation_state.dart';

class DeleteCostEstimationBloc
    extends Bloc<DeleteCostEstimationEvent, DeleteCostEstimationState> {
  final DeleteCostEstimationUseCase _deleteCostEstimationUseCase;

  DeleteCostEstimationBloc({
    required DeleteCostEstimationUseCase deleteCostEstimationUseCase,
  }) : _deleteCostEstimationUseCase = deleteCostEstimationUseCase,
       super(const DeleteCostEstimationInitial()) {
    on<DeleteCostEstimationStarted>(_onStarted);
    on<DeleteCostEstimationRequested>(_onRequested);
  }

  Future<void> _onStarted(
    DeleteCostEstimationStarted event,
    Emitter<DeleteCostEstimationState> emit,
  ) async {
    emit(const DeleteCostEstimationInitial());
  }

  Future<void> _onRequested(
    DeleteCostEstimationRequested event,
    Emitter<DeleteCostEstimationState> emit,
  ) async {
    emit(const DeleteCostEstimationInProgress());

    final result = await _deleteCostEstimationUseCase(
      estimationId: event.estimationId,
    );

    result.fold(
      (failure) {
        emit(
          DeleteCostEstimationFailure(
            message: 'Failed to delete cost estimation',
            failure: failure,
          ),
        );
      },
      (_) {
        emit(DeleteCostEstimationSuccess(estimationId: event.estimationId));
      },
    );
  }
}
