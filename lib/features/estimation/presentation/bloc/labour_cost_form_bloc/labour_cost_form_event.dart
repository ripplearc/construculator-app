part of 'labour_cost_form_bloc.dart';

sealed class LabourCostFormEvent {
  const LabourCostFormEvent();
}

class LabourCostItemTypeChanged extends LabourCostFormEvent {
  const LabourCostItemTypeChanged(this.value);

  final String value;
}

// TODO(CA-294): add LabourCostFormSubmitted event with estimateId and other field values
