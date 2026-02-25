import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'rename_estimation_event.dart';
part 'rename_estimation_state.dart';

class RenameEstimationBloc
    extends Bloc<RenameEstimationEvent, RenameEstimationState> {
  final CostEstimationRepository _repository;

  RenameEstimationBloc({required CostEstimationRepository repository})
    : _repository = repository,
      super(const RenameEstimationInitial()) {
    on<RenameEstimationTextChanged>(_onTextChanged);
    on<RenameEstimationRequested>(_onRenameEstimationRequested);
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
