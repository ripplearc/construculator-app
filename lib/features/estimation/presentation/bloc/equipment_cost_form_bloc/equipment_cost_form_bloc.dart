import 'package:flutter_bloc/flutter_bloc.dart';

part 'equipment_cost_form_event.dart';
part 'equipment_cost_form_state.dart';

/// BLoC for managing equipment cost item type input and validation.
class EquipmentCostFormBloc
    extends Bloc<EquipmentCostFormEvent, EquipmentCostFormState> {
  EquipmentCostFormBloc() : super(const EquipmentCostFormInitial()) {
    on<EquipmentCostItemTypeChanged>(_onItemTypeChanged);
    // TODO(CA-294): register EquipmentCostFormSubmitted and wire to CostItemRepository.createCostItem
  }

  void _onItemTypeChanged(
    EquipmentCostItemTypeChanged event,
    Emitter<EquipmentCostFormState> emit,
  ) {
    final current = state is EquipmentCostFormEditing
        ? state as EquipmentCostFormEditing
        : const EquipmentCostFormEditing();
    emit(
      current.copyWith(
        equipmentType: event.value,
        itemTypeError: event.value.trim().isEmpty ? 'itemTypeRequired' : null,
      ),
    );
  }
}
