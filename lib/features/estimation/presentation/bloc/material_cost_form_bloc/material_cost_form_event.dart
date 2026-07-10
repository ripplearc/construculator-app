part of 'material_cost_form_bloc.dart';

sealed class MaterialCostFormEvent {
  const MaterialCostFormEvent();
}

class MaterialCostItemTypeChanged extends MaterialCostFormEvent {
  const MaterialCostItemTypeChanged(this.value);

  final String value;
}

class MaterialCostFormSubmitted extends MaterialCostFormEvent {
  const MaterialCostFormSubmitted({required this.estimateId});

  final String estimateId;
  // TODO (CA-355): add other field values (unitPrice, quantity, etc.)
}
