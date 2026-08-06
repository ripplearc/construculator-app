part of 'labour_cost_form_bloc.dart';

/// Base sealed class for all labour cost form states.
sealed class LabourCostFormState {
  const LabourCostFormState();
}

/// Initial state before the user has interacted with the form.
class LabourCostFormInitial extends LabourCostFormState {
  const LabourCostFormInitial();
}

/// State while the user is filling in the labour cost form.
class LabourCostFormEditing extends LabourCostFormState {
  const LabourCostFormEditing({
    this.labourType = '',
    this.itemTypeError,
    this.calculationMethod,
    this.laborValue,
    this.crewSize,
    this.crewSizeError,
    this.hourlyRate,
    this.hourlyRateError,
  });

  /// The labour type value entered by the user.
  final String labourType;

  /// Validation error key for the item type field, or null when valid.
  final String? itemTypeError;
  final LaborCalculationMethodType? calculationMethod;
  final LaborValue? laborValue;
  final double? crewSize;
  final String? crewSizeError;
  final double? hourlyRate;
  final String? hourlyRateError;

  /// Whether the item type field contains a non-empty value.
  bool get isItemTypeValid => labourType.trim().isNotEmpty;
  bool get isHourlyRateValid => (hourlyRate ?? 0) > 0;
  bool get isCrewSizeValid => (crewSize ?? 0) > 0;

  double get perHourTotal {
    if (calculationMethod != LaborCalculationMethodType.perHour) return 0;
    return (hourlyRate ?? 0) * (laborValue?.laborHours ?? 0) * (crewSize ?? 0);
  }

  /// Returns a copy of this state with the given fields replaced.
  LabourCostFormEditing copyWith({
    String? labourType,
    Object? itemTypeError = _keep,
    Object? calculationMethod = _keep,
    Object? laborValue = _keep,
    Object? crewSize = _keep,
    Object? crewSizeError = _keep,
    Object? hourlyRate = _keep,
    Object? hourlyRateError = _keep,
  }) {
    return LabourCostFormEditing(
      labourType: labourType ?? this.labourType,
      itemTypeError: itemTypeError == _keep
          ? this.itemTypeError
          : itemTypeError as String?,
      calculationMethod: calculationMethod == _keep
          ? this.calculationMethod
          : calculationMethod as LaborCalculationMethodType?,
      laborValue:
          laborValue == _keep ? this.laborValue : laborValue as LaborValue?,
      crewSize: crewSize == _keep ? this.crewSize : crewSize as double?,
      crewSizeError: crewSizeError == _keep
          ? this.crewSizeError
          : crewSizeError as String?,
      hourlyRate:
          hourlyRate == _keep ? this.hourlyRate : hourlyRate as double?,
      hourlyRateError: hourlyRateError == _keep
          ? this.hourlyRateError
          : hourlyRateError as String?,
    );
  }
}

// TODO(CA-294): add LabourCostFormSubmitting, LabourCostFormSuccess, LabourCostFormFailure states

const Object _keep = Object();
