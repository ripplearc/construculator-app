import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_cost_estimation_event.dart';
part 'add_cost_estimation_state.dart';

/// Bloc for managing the cost estimation creation state and operations.
///
/// This bloc handles the creation of new cost estimations with proper
/// default values and follows the project's naming conventions and patterns
/// for BLoC implementation.
class AddCostEstimationBloc
    extends Bloc<AddCostEstimationEvent, AddCostEstimationState> {
  final AddCostEstimationUseCase _addCostEstimationUseCase;

  AddCostEstimationBloc({
    required AddCostEstimationUseCase addCostEstimationUseCase,
  }) : _addCostEstimationUseCase = addCostEstimationUseCase,
       super(const AddCostEstimationInitial()) {
    on<AddCostEstimationSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    AddCostEstimationSubmitted event,
    Emitter<AddCostEstimationState> emit,
  ) async {
    emit(const AddCostEstimationInProgress());

    final result = await _addCostEstimationUseCase(
      estimationName: event.estimationName,
      projectId: event.projectId,
      creatorUserId: event.creatorUserId,
    );

    result.fold(
      (failure) {
        emit(AddCostEstimationFailure(failure: failure));
      },
      (costEstimation) {
        emit(AddCostEstimationSuccess(costEstimation: costEstimation));
      },
    );
  }
}
