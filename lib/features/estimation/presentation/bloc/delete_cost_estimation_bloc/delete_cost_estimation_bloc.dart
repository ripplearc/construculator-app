import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'delete_cost_estimation_event.dart';
part 'delete_cost_estimation_state.dart';

class DeleteCostEstimationBloc
    extends Bloc<DeleteCostEstimationEvent, DeleteCostEstimationState> {
  final CostEstimationRepository _costEstimationRepository;
  final CurrentProjectNotifier _currentProjectNotifier;
  static final _logger = AppLogger().tag('DeleteCostEstimationBloc');

  DeleteCostEstimationBloc({
    required CostEstimationRepository costEstimationRepository,
    required CurrentProjectNotifier currentProjectNotifier,
  }) : _costEstimationRepository = costEstimationRepository,
       _currentProjectNotifier = currentProjectNotifier,
       super(const DeleteCostEstimationInitial()) {
    on<DeleteCostEstimationRequested>(_onRequested);
  }

  Future<void> _onRequested(
    DeleteCostEstimationRequested event,
    Emitter<DeleteCostEstimationState> emit,
  ) async {
    final projectId = _currentProjectNotifier.currentProjectId;
    if (projectId == null || projectId.isEmpty) {
      _logger.error('Current project ID is null or empty, cannot delete estimation');
      emit(
        const DeleteCostEstimationFailure(
          failure: EstimationFailure(
            errorType: EstimationErrorType.unexpectedError,
          ),
        ),
      );
      return;
    }

    emit(const DeleteCostEstimationInProgress());

    final result = await _costEstimationRepository.deleteEstimation(
      event.estimationId,
      projectId,
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
