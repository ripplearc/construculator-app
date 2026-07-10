part of 'equipment_cost_form_bloc.dart';

sealed class EquipmentCostFormEvent {
  const EquipmentCostFormEvent();
}

class EquipmentCostItemTypeChanged extends EquipmentCostFormEvent {
  const EquipmentCostItemTypeChanged(this.value);

  final String value;
}

class EquipmentCostFormSubmitted extends EquipmentCostFormEvent {
  const EquipmentCostFormSubmitted({required this.estimateId});

  final String estimateId;
  // TODO (CA-355): add other field values (unitPrice, quantity, etc.)
}
