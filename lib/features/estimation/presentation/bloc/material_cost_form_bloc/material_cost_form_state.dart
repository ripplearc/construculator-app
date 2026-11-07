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

  /// The quantity is larger than the database column can hold, or is so large
  /// that quantity times rate no longer fits the line total column.
  quantityTooLarge,

  /// The rate is below $0.01 or above $999,999.99.
  rateOutOfRange,
}

/// Whether the field that blocks Add has no value yet or has a bad one.
enum MaterialBlockerKind {
  /// The field is still empty.
  missing,

  /// The field holds a value that can't be used.
  invalid,
}

/// The first field, reading top to bottom, that keeps Add disabled.
class MaterialFormBlocker extends Equatable {
  const MaterialFormBlocker(this.field, this.kind);

  /// The field that blocks Add.
  final MaterialFormField field;

  /// Whether [field] is empty or holds a bad value.
  final MaterialBlockerKind kind;

  @override
  List<Object?> get props => [field, kind];
}

/// The units a saved price attached to the line can be counted in.
class AttachedPrice extends Equatable {
  const AttachedPrice({required this.buyUnit, this.measureUnit});

  /// The unit the material is bought in, which the price is per.
  final Unit buyUnit;

  /// The unit the material is measured in, when it has one besides
  /// [buyUnit], such as square feet for a panel bought by the sheet.
  final Unit? measureUnit;

  /// Whether the price still applies when the line is counted in [unit].
  bool allows(Unit unit) => unit == buyUnit || unit == measureUnit;

  @override
  List<Object?> get props => [buyUnit, measureUnit];
}

/// Base sealed class for all material cost form states.
sealed class MaterialCostFormState {
  const MaterialCostFormState();

  /// The form values entered so far; empty before the user has typed anything.
  MaterialCostFormData get data;
}

/// Initial state before the user has interacted with the form.
class MaterialCostFormInitial extends MaterialCostFormState {
  const MaterialCostFormInitial();

  @override
  MaterialCostFormData get data => const MaterialCostFormData();
}

/// State while the user is filling in the material cost form.
class MaterialCostFormEditing extends MaterialCostFormState {
  const MaterialCostFormEditing(this.data);

  /// The values entered so far and whether they are valid.
  @override
  final MaterialCostFormData data;
}

/// Full set of material form field values, carried by every state once the
/// user has started filling in the form.
class MaterialCostFormData extends Equatable {
  const MaterialCostFormData({
    this.itemName = '',
    this.quantity,
    this.unit,
    this.isUnitPicked = false,
    this.rate,
    this.rateStatus = RateStatus.missing,
    this.attachedPrice,
    this.isValid = false,
    this.fieldErrors = const {},
    this.hasUnsavedChanges = false,
  });

  /// The material name entered by the user.
  final String itemName;

  /// The quantity entered by the user, or null while empty or unreadable.
  final double? quantity;

  /// The unit the quantity is counted in, or null when there is none yet.
  ///
  /// Until the user picks one, it follows the attached price, then the unit
  /// last used for the typed material name.
  final Unit? unit;

  /// Whether the user picked [unit] from the unit list.
  final bool isUnitPicked;

  /// The price of one unit, or null while empty or unreadable.
  final double? rate;

  /// Confidence level of [rate].
  final RateStatus rateStatus;

  /// The saved price [rate] came from, or null when the rate was typed or is
  /// empty.
  final AttachedPrice? attachedPrice;

  /// Whether name, quantity, unit and rate are all present and in range.
  final bool isValid;

  /// Validation error by field, present only for a value that was entered and
  /// cannot be used. An empty field never has an entry: the disabled Add
  /// button names what is missing.
  final Map<MaterialFormField, MaterialFieldError> fieldErrors;

  /// Whether any of name, quantity, unit or rate differs from how the form
  /// opened. Typing a value and then restoring the original clears it.
  final bool hasUnsavedChanges;

  /// Quantity times rate rounded to the cent, or 0 while either is missing or
  /// unusable.
  double get lineTotal {
    final quantity = this.quantity;
    final rate = this.rate;
    if (quantity == null || rate == null) return 0;
    if (!quantity.isFinite || !rate.isFinite) return 0;
    return (quantity * (rate * 100).round()).roundToDouble() / 100;
  }

  /// Whether the name field contains a non-empty value.
  bool get isItemNameValid => itemName.trim().isNotEmpty;

  /// The first field that keeps Add disabled, or null when [isValid].
  MaterialFormBlocker? get blocker {
    if (isValid) return null;
    return _blockerFor(MaterialFormField.itemName, !isItemNameValid) ??
        _blockerFor(MaterialFormField.quantity, quantity == null) ??
        _blockerFor(MaterialFormField.unit, unit == null) ??
        _blockerFor(MaterialFormField.rate, rate == null);
  }

  MaterialFormBlocker? _blockerFor(MaterialFormField field, bool isEmpty) {
    if (fieldErrors.containsKey(field)) {
      return MaterialFormBlocker(field, MaterialBlockerKind.invalid);
    }
    if (isEmpty) return MaterialFormBlocker(field, MaterialBlockerKind.missing);
    return null;
  }

  /// Returns a copy with the given fields replaced. For a nullable field, an
  /// explicit value sets it, `null` clears it, and omitting the parameter
  /// keeps its current value.
  MaterialCostFormData copyWith({
    String? itemName,
    Object? quantity = _unset,
    Object? unit = _unset,
    bool? isUnitPicked,
    Object? rate = _unset,
    RateStatus? rateStatus,
    Object? attachedPrice = _unset,
    bool? isValid,
    Map<MaterialFormField, MaterialFieldError>? fieldErrors,
    bool? hasUnsavedChanges,
  }) {
    return MaterialCostFormData(
      itemName: itemName ?? this.itemName,
      quantity: quantity == _unset ? this.quantity : quantity as double?,
      unit: unit == _unset ? this.unit : unit as Unit?,
      isUnitPicked: isUnitPicked ?? this.isUnitPicked,
      rate: rate == _unset ? this.rate : rate as double?,
      rateStatus: rateStatus ?? this.rateStatus,
      attachedPrice: attachedPrice == _unset
          ? this.attachedPrice
          : attachedPrice as AttachedPrice?,
      isValid: isValid ?? this.isValid,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  @override
  List<Object?> get props => [
    itemName,
    quantity,
    unit,
    isUnitPicked,
    rate,
    rateStatus,
    attachedPrice,
    isValid,
    fieldErrors,
    hasUnsavedChanges,
  ];
}

/// State while the cost item is being saved.
class MaterialCostFormSubmitting extends MaterialCostFormState {
  const MaterialCostFormSubmitting(this.data);

  /// The form data being saved.
  @override
  final MaterialCostFormData data;
}

/// State when the cost item was saved.
class MaterialCostFormSuccess extends MaterialCostFormState {
  const MaterialCostFormSuccess(this.data, this.createdItem);

  /// The form data as it was when saved.
  @override
  final MaterialCostFormData data;

  /// The cost item as saved by [CostItemRepository.createCostItem].
  final CostItem createdItem;
}

/// State when saving the cost item failed. The form keeps every value so the
/// user can try again.
class MaterialCostFormFailure extends MaterialCostFormState {
  const MaterialCostFormFailure(this.data, this.failure);

  /// The form data as it was when saving failed.
  @override
  final MaterialCostFormData data;

  /// The failure returned by [CostItemRepository.createCostItem].
  final Failure failure;
}

const Object _unset = Object();
