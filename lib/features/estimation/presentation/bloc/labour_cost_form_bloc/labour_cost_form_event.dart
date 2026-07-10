part of 'labour_cost_form_bloc.dart';

sealed class LabourCostFormEvent {
  const LabourCostFormEvent();
}

class LabourCostItemTypeChanged extends LabourCostFormEvent {
  const LabourCostItemTypeChanged(this.value);

  final String value;
}

class LabourCostFormSubmitted extends LabourCostFormEvent {
  const LabourCostFormSubmitted({required this.estimateId});

  final String estimateId;
  // TODO (CA-355): add other field values (crewRate, laborValue, etc.)
}
