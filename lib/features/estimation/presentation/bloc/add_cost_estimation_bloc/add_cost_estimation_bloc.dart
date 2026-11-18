import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_cost_estimation_event.dart';
part 'add_cost_estimation_state.dart';

/// Bloc for managing the cost estimation creation state and operations.
///
/// This bloc handles the creation of new cost estimations with proper
/// default values and follows the project's naming conventions and patterns
/// for BLoC implementation.
///
/// A user without the add permission on the current project gets a permission
/// failure before anything is written, because the phone accepts the write
/// for every role and the server only refuses it at upload.
class AddCostEstimationBloc
    extends Bloc<AddCostEstimationEvent, AddCostEstimationState> {
  final AddCostEstimationUseCase _addCostEstimationUseCase;
  final ProjectRepository _projectRepository;
  final CurrentProjectNotifier _currentProjectNotifier;

  AddCostEstimationBloc({
    required this._addCostEstimationUseCase,
    required this._projectRepository,
    required this._currentProjectNotifier,
  }) : super(const AddCostEstimationInitial()) {
    on<AddCostEstimationSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    AddCostEstimationSubmitted event,
    Emitter<AddCostEstimationState> emit,
  ) async {
    final projectId = _currentProjectNotifier.currentProjectId;
    if (projectId != null &&
        !_projectRepository.hasProjectPermission(
          projectId,
          PermissionConstants.addCostEstimation,
        )) {
      emit(
        const AddCostEstimationFailure(
          failure: EstimationFailure(
            errorType: EstimationErrorType.permissionDenied,
          ),
        ),
      );
      return;
    }

    emit(const AddCostEstimationInProgress());

    final result = await _addCostEstimationUseCase(
      estimationName: event.estimationName,
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
