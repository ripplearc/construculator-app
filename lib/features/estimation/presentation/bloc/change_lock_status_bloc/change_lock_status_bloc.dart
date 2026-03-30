import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'change_lock_status_event.dart';
part 'change_lock_status_state.dart';

class ChangeLockStatusBloc
    extends Bloc<ChangeLockStatusEvent, ChangeLockStatusState> {
  final CostEstimationRepository _repository;

  ChangeLockStatusBloc({required CostEstimationRepository repository})
    : _repository = repository,
      super(const ChangeLockStatusInitial()) {
    on<ChangeLockStatusRequested>(_onChangeLockStatusRequested);
  }

  Future<void> _onChangeLockStatusRequested(
    ChangeLockStatusRequested event,
    Emitter<ChangeLockStatusState> emit,
  ) async {
    if (state is ChangeLockStatusInProgress) return;

    emit(const ChangeLockStatusInProgress());

    final result = await _repository.changeLockStatus(
      estimationId: event.estimationId,
      isLocked: event.isLocked,
      projectId: event.projectId,
    );

    result.fold(
      (failure) => emit(ChangeLockStatusFailure(failure)),
      (costEstimate) =>
          emit(ChangeLockStatusSuccess(costEstimate.lockStatus.isLocked)),
    );
  }
}
