import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'equipment_cost_form_event.dart';
part 'equipment_cost_form_state.dart';

class EquipmentCostFormBloc
    extends Bloc<EquipmentCostFormEvent, EquipmentCostFormState> {
  EquipmentCostFormBloc({required CostItemRepository repository})
    : _repository = repository,
      super(const EquipmentCostFormInitial()) {
    on<EquipmentCostItemTypeChanged>(_onItemTypeChanged);
    on<EquipmentCostFormSubmitted>(_onSubmitted);
  }

  final CostItemRepository _repository;

  void _onItemTypeChanged(
    EquipmentCostItemTypeChanged event,
    Emitter<EquipmentCostFormState> emit,
  ) {
    final current = state is EquipmentCostFormEditing
        ? state as EquipmentCostFormEditing
        : const EquipmentCostFormEditing();
    emit(
      current.copyWith(
        equipmentName: event.value,
        itemTypeError: event.value.trim().isEmpty ? 'itemTypeRequired' : null,
      ),
    );
  }

  Future<void> _onSubmitted(
    EquipmentCostFormSubmitted event,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    final editing = state is EquipmentCostFormEditing
        ? state as EquipmentCostFormEditing
        : const EquipmentCostFormEditing();

    if (!editing.isItemTypeValid) {
      emit(editing.copyWith(itemTypeError: 'itemTypeRequired'));
      return;
    }

    emit(const EquipmentCostFormSubmitting());

    final now = DateTime.now();
    final item = EquipmentCostItem(
      id: '',
      estimateId: event.estimateId,
      itemName: editing.equipmentName,
      calculation: const {},
      itemTotalCost: 0,
      createdAt: now,
      updatedAt: now,
      currency: 'USD',
      unitPrice: const Money(amount: 0),
      quantity: const Quantity(value: 0, unit: Unit.pieces),
    );

    final result = await _repository.createCostItem(item);

    result.fold(
      (failure) => emit(EquipmentCostFormFailure(failure: failure)),
      (created) => emit(EquipmentCostFormSuccess(item: created)),
    );
  }
}
