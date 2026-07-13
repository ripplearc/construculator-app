part of 'material_cost_form_bloc.dart';

/// Base sealed class for all material cost form events.
sealed class MaterialCostFormEvent {
  const MaterialCostFormEvent();
}

/// Fired when the user changes the material type selection.
class MaterialCostItemTypeChanged extends MaterialCostFormEvent {
  const MaterialCostItemTypeChanged(this.value);

  /// The new item type value entered by the user.
  final String value;
}

class MaterialCostItemUnitChanged extends MaterialCostFormEvent {
  const MaterialCostItemUnitChanged(this.unit);

  final Unit? unit;
}

// TODO(CA-294): add MaterialCostFormSubmitted event with estimateId and other field values
