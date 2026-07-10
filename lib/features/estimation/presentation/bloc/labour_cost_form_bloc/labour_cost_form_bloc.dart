import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'labour_cost_form_event.dart';
part 'labour_cost_form_state.dart';

class LabourCostFormBloc
    extends Bloc<LabourCostFormEvent, LabourCostFormState> {
  LabourCostFormBloc({required CostItemRepository repository})
    : _repository = repository,
      super(const LabourCostFormInitial()) {
    on<LabourCostItemTypeChanged>(_onItemTypeChanged);
    on<LabourCostFormSubmitted>(_onSubmitted);
  }

  final CostItemRepository _repository;

  void _onItemTypeChanged(
    LabourCostItemTypeChanged event,
    Emitter<LabourCostFormState> emit,
  ) {
    final current = state is LabourCostFormEditing
        ? state as LabourCostFormEditing
        : const LabourCostFormEditing();
    emit(
      current.copyWith(
        labourType: event.value,
        itemTypeError: event.value.trim().isEmpty ? 'itemTypeRequired' : null,
      ),
    );
  }

  Future<void> _onSubmitted(
    LabourCostFormSubmitted event,
    Emitter<LabourCostFormState> emit,
  ) async {
    final editing = state is LabourCostFormEditing
        ? state as LabourCostFormEditing
        : const LabourCostFormEditing();

    if (!editing.isItemTypeValid) {
      emit(editing.copyWith(itemTypeError: 'itemTypeRequired'));
      return;
    }

    emit(const LabourCostFormSubmitting());

    final now = DateTime.now();
    final item = LaborCostItem(
      id: '',
      estimateId: event.estimateId,
      itemName: editing.labourType,
      calculation: const {},
      itemTotalCost: 0,
      createdAt: now,
      updatedAt: now,
      currency: 'USD',
      laborCalcMethod: LaborCalculationMethodType.perDay,
      laborValue: const LaborValue(),
    );

    final result = await _repository.createCostItem(item);

    result.fold(
      (failure) => emit(LabourCostFormFailure(failure: failure)),
      (created) => emit(LabourCostFormSuccess(item: created)),
    );
  }
}
