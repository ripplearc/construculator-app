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

class LabourCostCalculationMethodChanged extends LabourCostFormEvent {
  const LabourCostCalculationMethodChanged(this.calculationMethod);

  final LaborCalculationMethodType? calculationMethod;
}

class LabourCostLaborValueUpdated extends LabourCostFormEvent {
  const LabourCostLaborValueUpdated(this.laborValue);

  final LaborValue? laborValue;
}

class LabourCostCrewSizeUpdated extends LabourCostFormEvent {
  const LabourCostCrewSizeUpdated(this.crewSize);

  final double? crewSize;
}

class LabourCostHourlyRateUpdated extends LabourCostFormEvent {
  const LabourCostHourlyRateUpdated(this.value);

  final String value;
}

// TODO(CA-294): add LabourCostFormSubmitted event with estimateId and other field values
