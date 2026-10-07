part of 'material_cost_form_bloc.dart';

/// The material form fields that can block the Add button.
enum MaterialFormField {
  /// The material name.
  itemName,

  /// How much of the material is bought.
  quantity,

  /// The unit the quantity is counted in.
  unit,

  /// The price of one unit.
  rate,
}

/// Why a value entered in a [MaterialFormField] can't be used.
enum MaterialFieldError {
  /// The quantity is zero, negative or not a number.
  quantityNotPositive,

  /// The quantity is larger than the database column can hold.
  quantityTooLarge,

  /// The rate is below $0.01 or above $999,999.99.
  rateOutOfRange,
}

/// Base sealed class for all material cost form states.
sealed class MaterialCostFormState {
  const MaterialCostFormState();
}

/// Initial state before the user has interacted with the form.
class MaterialCostFormInitial extends MaterialCostFormState {
  const MaterialCostFormInitial();
}

/// State while the user is filling in the material cost form.
class MaterialCostFormEditing extends MaterialCostFormState {
  const MaterialCostFormEditing(this.data);

  /// The values entered so far and whether they are valid.
  final MaterialCostFormData data;
}

/// Full set of material form field values, carried by every state once the
/// user has started filling in the form.
class MaterialCostFormData extends Equatable {
  const MaterialCostFormData({
    this.itemName = '',
    this.quantity,
    this.unit,
    this.rate,
    this.rateStatus = RateStatus.missing,
    this.isValid = false,
    this.fieldErrors = const {},
  });

  /// The material name entered by the user.
  final String itemName;

  /// The quantity entered by the user, or null while empty or unreadable.
  final double? quantity;

  /// The unit picked from the unit list, or null when none is picked.
  final Unit? unit;

  /// The price of one unit, or null while empty or unreadable.
  final double? rate;

  /// Confidence level of [rate].
  final RateStatus rateStatus;

  /// Whether name, quantity, unit and rate are all present and in range.
  final bool isValid;

  /// Validation error by field, present only for a value that was entered and
  /// cannot be used. An empty field never has an entry: the disabled Add
  /// button names what is missing.
  final Map<MaterialFormField, MaterialFieldError> fieldErrors;

  /// Whether the name field contains a non-empty value.
  bool get isItemNameValid => itemName.trim().isNotEmpty;

  /// Returns a copy with the given fields replaced. For a nullable field, an
  /// explicit value sets it, `null` clears it, and omitting the parameter
  /// keeps its current value.
  MaterialCostFormData copyWith({
    String? itemName,
    Object? quantity = _unset,
    Object? unit = _unset,
    Object? rate = _unset,
    RateStatus? rateStatus,
    bool? isValid,
    Map<MaterialFormField, MaterialFieldError>? fieldErrors,
  }) {
    return MaterialCostFormData(
      itemName: itemName ?? this.itemName,
      quantity: quantity == _unset ? this.quantity : quantity as double?,
      unit: unit == _unset ? this.unit : unit as Unit?,
      rate: rate == _unset ? this.rate : rate as double?,
      rateStatus: rateStatus ?? this.rateStatus,
      isValid: isValid ?? this.isValid,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => [
    itemName,
    quantity,
    unit,
    rate,
    rateStatus,
    isValid,
    fieldErrors,
  ];
}

// TODO(CA-294): add MaterialCostFormSubmitting, MaterialCostFormSuccess, MaterialCostFormFailure states

const Object _unset = Object();
