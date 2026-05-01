import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'rename_estimation_event.dart';
part 'rename_estimation_state.dart';

class RenameEstimationBloc
    extends Bloc<RenameEstimationEvent, RenameEstimationState> {
  final CostEstimationRepository _repository;
  final ProjectRepository _projectRepository;

  RenameEstimationBloc({
    required CostEstimationRepository repository,
    required ProjectRepository projectRepository,
  }) : _repository = repository,
       _projectRepository = projectRepository,
       super(const RenameEstimationInitial()) {
    on<RenameEstimationReset>(_onReset);
    on<RenameEstimationTextChanged>(_onTextChanged);
    on<RenameEstimationRequested>(_onRenameEstimationRequested);
  }

  void _onReset(
    RenameEstimationReset event,
    Emitter<RenameEstimationState> emit,
  ) {
    emit(const RenameEstimationInitial());
  }

  void _onTextChanged(
    RenameEstimationTextChanged event,
    Emitter<RenameEstimationState> emit,
  ) {
    final isSaveEnabled = event.text.trim().isNotEmpty;
    emit(RenameEstimationEditing(isSaveEnabled: isSaveEnabled));
  }

  Future<void> _onRenameEstimationRequested(
    RenameEstimationRequested event,
    Emitter<RenameEstimationState> emit,
  ) async {
    final trimmedName = event.newName.trim();
    final isSaveEnabled = trimmedName.isNotEmpty;

    final hasPermission = _projectRepository.hasProjectPermission(
      event.projectId,
      PermissionConstants.editCostEstimation,
    );

    if (!hasPermission) {
      emit(
        RenameEstimationFailure(
          const EstimationFailure(
            errorType: EstimationErrorType.permissionDenied,
          ),
          isSaveEnabled: isSaveEnabled,
        ),
      );
      return;
    }

    emit(RenameEstimationInProgress(isSaveEnabled: isSaveEnabled));

    final result = await _repository.renameEstimation(
      estimationId: event.estimationId,
      newName: trimmedName,
      projectId: event.projectId,
    );

    result.fold(
      (failure) =>
          emit(RenameEstimationFailure(failure, isSaveEnabled: isSaveEnabled)),
      (costEstimate) =>
          emit(RenameEstimationSuccess(costEstimate.estimateName)),
    );
  }
}
