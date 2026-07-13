import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'material_cost_form_event.dart';
part 'material_cost_form_state.dart';

/// BLoC for managing material cost item type input and validation.
class MaterialCostFormBloc
    extends Bloc<MaterialCostFormEvent, MaterialCostFormState> {
  MaterialCostFormBloc() : super(const MaterialCostFormInitial()) {
    on<MaterialCostItemTypeChanged>(_onItemTypeChanged);
    on<MaterialCostItemUnitChanged>(_onUnitChanged);
    // TODO(CA-294): register MaterialCostFormSubmitted and wire to CostItemRepository.createCostItem
  }

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

  void _onUnitChanged(
    MaterialCostItemUnitChanged event,
    Emitter<MaterialCostFormState> emit,
  ) {
    final current = state is MaterialCostFormEditing
        ? state as MaterialCostFormEditing
        : const MaterialCostFormEditing();
    emit(
      current.copyWith(
        selectedUnit: event.unit,
        unitError: event.unit == null ? 'uomRequiredError' : null,
      ),
    );
  }
}
