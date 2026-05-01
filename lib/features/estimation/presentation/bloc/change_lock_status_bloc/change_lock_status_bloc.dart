import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'change_lock_status_event.dart';
part 'change_lock_status_state.dart';

class ChangeLockStatusBloc
    extends Bloc<ChangeLockStatusEvent, ChangeLockStatusState> {
  final CostEstimationRepository _repository;
  final ProjectRepository _projectRepository;

  ChangeLockStatusBloc({
    required CostEstimationRepository repository,
    required ProjectRepository projectRepository,
  }) : _repository = repository,
       _projectRepository = projectRepository,
       super(const ChangeLockStatusInitial()) {
    on<ChangeLockStatusRequested>(_onChangeLockStatusRequested);
  }

  Future<void> _onChangeLockStatusRequested(
    ChangeLockStatusRequested event,
    Emitter<ChangeLockStatusState> emit,
  ) async {
    if (state is ChangeLockStatusInProgress) return;

    final originalValue = !event.isLocked;

    final hasPermission = _projectRepository.hasProjectPermission(
      event.projectId,
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
      projectId: event.projectId,
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
