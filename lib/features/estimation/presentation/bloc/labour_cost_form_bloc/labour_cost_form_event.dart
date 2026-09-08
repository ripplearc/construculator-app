part of 'labour_cost_form_bloc.dart';

/// Base sealed class for all labour cost form events.
sealed class LabourCostFormEvent {
  const LabourCostFormEvent();
}

/// Fired when the user changes the labour type selection.
class LabourCostItemTypeChanged extends LabourCostFormEvent {
  const LabourCostItemTypeChanged(this.value);

  /// The new item type value entered by the user.
  final String value;
}

// TODO(CA-294): add LabourCostFormSubmitted event with estimateId and other field values
