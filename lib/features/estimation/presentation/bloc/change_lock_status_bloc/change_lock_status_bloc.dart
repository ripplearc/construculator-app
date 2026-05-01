import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'change_lock_status_event.dart';
part 'change_lock_status_state.dart';

class ChangeLockStatusBloc
    extends Bloc<ChangeLockStatusEvent, ChangeLockStatusState> {
  final CostEstimationRepository _repository;
  final ProjectRepository _projectRepository;
  final CurrentProjectNotifier _currentProjectNotifier;

  ChangeLockStatusBloc({
    required CostEstimationRepository repository,
    required ProjectRepository projectRepository,
    required CurrentProjectNotifier currentProjectNotifier,
  }) : _repository = repository,
       _projectRepository = projectRepository,
       _currentProjectNotifier = currentProjectNotifier,
       super(const ChangeLockStatusInitial()) {
    on<ChangeLockStatusRequested>(_onChangeLockStatusRequested);
  }

  Future<void> _onChangeLockStatusRequested(
    ChangeLockStatusRequested event,
    Emitter<ChangeLockStatusState> emit,
  ) async {
    if (state is ChangeLockStatusInProgress) return;

    final projectId = _currentProjectNotifier.currentProjectId;
    final originalValue = !event.isLocked;

    if (projectId == null) {
      emit(
        ChangeLockStatusFailure(
          failure: const EstimationFailure(
            errorType: EstimationErrorType.unexpectedError,
          ),
          originalValue: originalValue,
        ),
      );
      return;
    }

    final hasPermission = _projectRepository.hasProjectPermission(
      projectId,
      PermissionConstants.lockCostEstimation,
    );

    if (!hasPermission) {
      emit(
        ChangeLockStatusFailure(
          failure: const EstimationFailure(
            errorType: EstimationErrorType.permissionDenied,
          ),
          originalValue: originalValue,
        ),
      );
      return;
    }

    emit(const ChangeLockStatusInProgress());

    final result = await _repository.changeLockStatus(
      estimationId: event.estimationId,
      isLocked: event.isLocked,
      projectId: projectId,
    );

    result.fold(
      (failure) => emit(
        ChangeLockStatusFailure(failure: failure, originalValue: originalValue),
      ),
      (costEstimate) =>
          emit(ChangeLockStatusSuccess(costEstimate.lockStatus.isLocked)),
    );
  }
}
