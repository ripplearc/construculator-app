part of 'equipment_cost_form_bloc.dart';

sealed class EquipmentCostFormEvent {
  const EquipmentCostFormEvent();
}

class EquipmentCostItemTypeChanged extends EquipmentCostFormEvent {
  const EquipmentCostItemTypeChanged(this.value);

  final String value;
}

// TODO(CA-294): add EquipmentCostFormSubmitted event with estimateId and other field values
