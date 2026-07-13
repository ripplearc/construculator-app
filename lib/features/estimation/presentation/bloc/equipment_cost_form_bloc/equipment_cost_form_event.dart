part of 'equipment_cost_form_bloc.dart';

/// Base sealed class for all equipment cost form events.
sealed class EquipmentCostFormEvent {
  const EquipmentCostFormEvent();
}

/// Fired when the user changes the equipment type selection.
class EquipmentCostItemTypeChanged extends EquipmentCostFormEvent {
  const EquipmentCostItemTypeChanged(this.value);

  /// The new item type value entered by the user.
  final String value;
}

class EquipmentCostUnitPriceChanged extends EquipmentCostFormEvent {
  const EquipmentCostUnitPriceChanged(this.value);

  final String value;
}

// TODO(CA-294): add EquipmentCostFormSubmitted event with estimateId and other field values
