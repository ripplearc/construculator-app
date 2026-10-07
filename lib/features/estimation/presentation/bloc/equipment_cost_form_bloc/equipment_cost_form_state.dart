part of 'equipment_cost_form_bloc.dart';

/// The equipment form fields that can carry a validation error.
enum EquipmentFormField {
  /// The equipment name.
  itemType,

  /// The number of days, on a Day line.
  duration,

  /// The rate per day, on a Day line.
  dailyRate,

  /// The fixed price, on a Job line.
  jobAmount,

  /// The optional delivery fee.
  deliveryFee,
}

/// Why a value entered in an [EquipmentFormField] can't be used.
enum EquipmentFieldError {
  /// The duration is zero or below.
  durationNotPositive,

  /// The duration is above what the database column can hold.
  durationTooLarge,

  /// The duration is not a whole or half day.
  durationNotHalfDay,

  /// The rate or amount is below $0.01 or above $999,999.99.
  rateOutOfRange,
}

/// What stops the equipment form from being submitted, in the order the form
/// shows its fields from top to bottom.
enum EquipmentSubmitBlocker {
  /// The equipment name is empty.
  missingName,

  /// The Day duration is empty.
  missingDuration,

  /// The Day duration is zero or below.
  durationNotAboveZero,

  /// The Day duration has an error other than zero or below.
  invalidDuration,

  /// The Day rate is empty.
  missingRate,

  /// The Day rate has an error.
  invalidRate,

  /// The Job amount is empty.
  missingAmount,

  /// The Job amount has an error.
  invalidAmount,

  /// The delivery fee has an error.
  invalidDeliveryFee,
}

/// Base sealed class for all equipment cost form states.
sealed class EquipmentCostFormState {
  const EquipmentCostFormState();

  /// The form's field values; empty defaults before the user has started.
  EquipmentCostFormData get data;
}

/// Initial state before the user has interacted with the form.
class EquipmentCostFormInitial extends EquipmentCostFormState {
  const EquipmentCostFormInitial();

  @override
  EquipmentCostFormData get data => const EquipmentCostFormData();
}

/// Full set of equipment form field values, carried by every state once the
/// user has started filling in the form.
class EquipmentCostFormData extends Equatable {
  const EquipmentCostFormData({
    this.method = EquipmentPricingMethod.day,
    this.equipmentType = '',
    this.duration,
    this.dailyRate,
    this.jobAmount,
    this.deliveryFee,
    this.rateStatus = RateStatus.missing,
    this.description,
    this.isValid = false,
    this.fieldErrors = const {},
  });

  /// Pricing strategy currently selected: by the day or by the job.
  final EquipmentPricingMethod method;

  /// The equipment type/name value entered by the user.
  final String equipmentType;

  /// Raw duration/dailyRate/jobAmount/deliveryFee values entered by the user;
  /// only the pair relevant to [method] is meaningful.
  final double? duration, dailyRate, jobAmount, deliveryFee;

  /// Confidence level of the rate used for this line.
  final RateStatus rateStatus;

  /// Freeform description/note for this item.
  final String? description;

  /// Whether the required fields for the current [method] are all filled and
  /// within bounds.
  final bool isValid;

  /// Validation error by field, present only for a value that was entered and
  /// cannot be used. An empty field never has an entry: the disabled Add
  /// button names what is missing, so an empty field is never shown as an
  /// error.
  final Map<EquipmentFormField, EquipmentFieldError> fieldErrors;

  /// Validation error key for the item type field, or null when valid.
  EquipmentFieldError? get itemTypeError =>
      fieldErrors[EquipmentFormField.itemType];

  /// The cost before delivery: duration x daily rate for Day, the amount for
  /// Job, rounded to the cent (half a cent rounds up). Empty fields count as
  /// zero.
  double get baseCost => _roundToCents(
    method == EquipmentPricingMethod.day
        ? (duration ?? 0) * (dailyRate ?? 0)
        : (jobAmount ?? 0),
  );

  /// [baseCost] plus the delivery fee: a line is the sum of its rounded
  /// parts. Delivery is added after the rate math, never inside it, and a fee
  /// with an error is left out.
  double get lineTotal =>
      baseCost +
      (fieldErrors.containsKey(EquipmentFormField.deliveryFee)
          ? 0
          : _roundToCents(deliveryFee ?? 0));

  /// The first field, from top to bottom, that is empty or has an error, or
  /// null when the form can be submitted.
  EquipmentSubmitBlocker? get submitBlocker {
    if (!isItemTypeValid) return EquipmentSubmitBlocker.missingName;
    if (method == EquipmentPricingMethod.day) {
      final durationError = fieldErrors[EquipmentFormField.duration];
      if (duration == null) return EquipmentSubmitBlocker.missingDuration;
      if (durationError == EquipmentFieldError.durationNotPositive) {
        return EquipmentSubmitBlocker.durationNotAboveZero;
      }
      if (durationError != null) return EquipmentSubmitBlocker.invalidDuration;
      if (dailyRate == null) return EquipmentSubmitBlocker.missingRate;
      if (fieldErrors.containsKey(EquipmentFormField.dailyRate)) {
        return EquipmentSubmitBlocker.invalidRate;
      }
    } else {
      if (jobAmount == null) return EquipmentSubmitBlocker.missingAmount;
      if (fieldErrors.containsKey(EquipmentFormField.jobAmount)) {
        return EquipmentSubmitBlocker.invalidAmount;
      }
    }
    if (fieldErrors.containsKey(EquipmentFormField.deliveryFee)) {
      return EquipmentSubmitBlocker.invalidDeliveryFee;
    }
    return null;
  }

  /// Whether the item type field contains a non-empty value.
  bool get isItemTypeValid => equipmentType.trim().isNotEmpty;

  /// Returns a copy with the given fields replaced. For a nullable field, an
  /// explicit value sets it, `null` clears it, and omitting the parameter
  /// keeps its current value.
  EquipmentCostFormData copyWith({
    EquipmentPricingMethod? method,
    String? equipmentType,
    Object? duration = _unset,
    Object? dailyRate = _unset,
    Object? jobAmount = _unset,
    Object? deliveryFee = _unset,
    RateStatus? rateStatus,
    Object? description = _unset,
    bool? isValid,
    Map<EquipmentFormField, EquipmentFieldError>? fieldErrors,
  }) {
    return EquipmentCostFormData(
      method: method ?? this.method,
      equipmentType: equipmentType ?? this.equipmentType,
      duration: duration == _unset ? this.duration : duration as double?,
      dailyRate: dailyRate == _unset ? this.dailyRate : dailyRate as double?,
      jobAmount: jobAmount == _unset ? this.jobAmount : jobAmount as double?,
      deliveryFee: deliveryFee == _unset
          ? this.deliveryFee
          : deliveryFee as double?,
      rateStatus: rateStatus ?? this.rateStatus,
      description: description == _unset
          ? this.description
          : description as String?,
      isValid: isValid ?? this.isValid,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => [
    method,
    equipmentType,
    duration,
    dailyRate,
    jobAmount,
    deliveryFee,
    rateStatus,
    description,
    isValid,
    fieldErrors,
  ];
}

/// State while the user is filling in the equipment cost form.
class EquipmentCostFormEditing extends EquipmentCostFormState {
  const EquipmentCostFormEditing(this.data);

  /// The form's current field values and validation results.
  @override
  final EquipmentCostFormData data;

  /// Kept as a direct getter so existing item-type field widget code doesn't
  /// need to know about [EquipmentCostFormData].
  EquipmentFieldError? get itemTypeError => data.itemTypeError;
}

/// State while a delivery fee larger than the base cost (duration x rate for
/// Day, the amount for Job) needs explicit user confirmation before
/// submission proceeds.
///
/// Entered from [EquipmentCostSubmittedEvent]. [EquipmentOutsizedFeeAcceptedEvent]
/// continues to submission and [EquipmentOutsizedFeeDeclinedEvent] returns to
/// editing.
class EquipmentCostFormOutsizedFeeConfirm extends EquipmentCostFormState {
  const EquipmentCostFormOutsizedFeeConfirm(this.data);

  /// The validated form data awaiting the user's outsized-fee decision.
  @override
  final EquipmentCostFormData data;
}

/// State while the cost item is being submitted to the repository.
class EquipmentCostFormSubmitting extends EquipmentCostFormState {
  const EquipmentCostFormSubmitting(this.data);

  /// The form data being submitted.
  @override
  final EquipmentCostFormData data;
}

/// State when the cost item was submitted successfully.
class EquipmentCostFormSuccess extends EquipmentCostFormState {
  const EquipmentCostFormSuccess(this.data, this.createdItem);

  /// The form data as it was at submission time.
  @override
  final EquipmentCostFormData data;

  /// The cost item as persisted by [CostItemRepository.createCostItem].
  final CostItem createdItem;
}

/// State when submitting the cost item failed.
class EquipmentCostFormFailure extends EquipmentCostFormState {
  const EquipmentCostFormFailure(this.data, this.failure);

  /// The form data as it was at submission time.
  @override
  final EquipmentCostFormData data;

  /// The failure returned by [CostItemRepository.createCostItem].
  final Failure failure;
}

double _roundToCents(double amount) => (amount * 100).round() / 100;

const Object _unset = Object();
