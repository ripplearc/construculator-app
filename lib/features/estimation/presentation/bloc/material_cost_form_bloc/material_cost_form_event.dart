part of 'material_cost_form_bloc.dart';

sealed class MaterialCostFormEvent {
  const MaterialCostFormEvent();
}

class MaterialCostItemTypeChanged extends MaterialCostFormEvent {
  const MaterialCostItemTypeChanged(this.value);

  final String value;
}

// TODO(CA-294): add MaterialCostFormSubmitted event with estimateId and other field values
