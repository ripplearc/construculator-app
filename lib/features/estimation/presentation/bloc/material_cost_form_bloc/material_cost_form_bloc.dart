import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'material_cost_form_event.dart';
part 'material_cost_form_state.dart';

class MaterialCostFormBloc
    extends Bloc<MaterialCostFormEvent, MaterialCostFormState> {
  MaterialCostFormBloc({required CostItemRepository repository})
    : _repository = repository,
      super(const MaterialCostFormInitial()) {
    on<MaterialCostItemTypeChanged>(_onItemTypeChanged);
    on<MaterialCostFormSubmitted>(_onSubmitted);
  }

  final CostItemRepository _repository;

  void _onItemTypeChanged(
    MaterialCostItemTypeChanged event,
    Emitter<MaterialCostFormState> emit,
  ) {
    final current = state is MaterialCostFormEditing
        ? state as MaterialCostFormEditing
        : const MaterialCostFormEditing();
    emit(
      current.copyWith(
        materialType: event.value,
        itemTypeError: event.value.trim().isEmpty ? 'itemTypeRequired' : null,
      ),
    );
  }

  Future<void> _onSubmitted(
    MaterialCostFormSubmitted event,
    Emitter<MaterialCostFormState> emit,
  ) async {
    final editing = state is MaterialCostFormEditing
        ? state as MaterialCostFormEditing
        : const MaterialCostFormEditing();

    if (!editing.isItemTypeValid) {
      emit(editing.copyWith(itemTypeError: 'itemTypeRequired'));
      return;
    }

    emit(const MaterialCostFormSubmitting());

    final now = DateTime.now();
    final item = MaterialCostItem(
      id: '',
      estimateId: event.estimateId,
      itemName: editing.materialType,
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
      (failure) => emit(
        MaterialCostFormFailure(failure: failure),
      ),
      (created) => emit(MaterialCostFormSuccess(item: created)),
    );
  }
}
