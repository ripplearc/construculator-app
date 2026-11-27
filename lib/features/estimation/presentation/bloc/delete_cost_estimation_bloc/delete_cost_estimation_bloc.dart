import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'delete_cost_estimation_event.dart';
part 'delete_cost_estimation_state.dart';

class DeleteCostEstimationBloc
    extends Bloc<DeleteCostEstimationEvent, DeleteCostEstimationState> {
  final CostEstimationRepository _costEstimationRepository;
  final ProjectRepository _projectRepository;
  final CurrentProjectNotifier _currentProjectNotifier;
  static final _logger = AppLogger().tag('DeleteCostEstimationBloc');

  DeleteCostEstimationBloc({
    required this._costEstimationRepository,
    required this._projectRepository,
    required this._currentProjectNotifier,
  }) : super(const DeleteCostEstimationInitial()) {
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

    final hasPermission = _projectRepository.hasProjectPermission(
      projectId,
      PermissionConstants.deleteCostEstimation,
    );
    if (!hasPermission) {
      emit(
        const DeleteCostEstimationFailure(
          failure: EstimationFailure(
            errorType: EstimationErrorType.permissionDenied,
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
