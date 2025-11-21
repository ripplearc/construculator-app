import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'delete_cost_estimation_event.dart';
part 'delete_cost_estimation_state.dart';

class DeleteCostEstimationBloc
    extends Bloc<DeleteCostEstimationEvent, DeleteCostEstimationState> {
  final CostEstimationRepository _costEstimationRepository;
  DeleteCostEstimationBloc({
    required CostEstimationRepository costEstimationRepository,
  }) : _costEstimationRepository = costEstimationRepository,
       super(const DeleteCostEstimationInitial()) {
    on<DeleteCostEstimationRequested>(_onRequested);
  }

  Future<void> _onRequested(
    DeleteCostEstimationRequested event,
    Emitter<DeleteCostEstimationState> emit,
  ) async {
    emit(const DeleteCostEstimationInProgress());

    final result = await _costEstimationRepository.deleteEstimation(
      event.estimationId,
      event.projectId,
    );

    result.fold(
      (failure) {
        emit(DeleteCostEstimationFailure(failure: failure));
      },
      (_) {
        emit(DeleteCostEstimationSuccess(estimationId: event.estimationId));
      },
    );
  }
}
