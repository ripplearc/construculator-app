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
    this.rate,
    this.rateStatus = RateStatus.missing,
    this.isValid = false,
    this.fieldErrors = const {},
    this.hasUnsavedChanges = false,
    this.editedItem,
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

  /// Whether any of name, quantity, unit or rate differs from how the form
  /// opened. Typing a value and then restoring the original clears it.
  final bool hasUnsavedChanges;

  /// The line already on the estimate that this form edits, or `null` when
  /// the form adds a new line.
  final MaterialCostItem? editedItem;

  /// Whether Save changes a line already on the estimate.
  bool get isEditingExistingLine => editedItem != null;

  /// The name that titles the form and its questions: the stored name of the
  /// line being edited, which stays put while the name field is changed, or
  /// else the name typed so far.
  String get lineName => editedItem?.itemName ?? itemName;

  /// How much the estimate total moves if the form is saved now, in dollars.
  ///
  /// `null` when the form adds a new line, so there is nothing to compare.
  double? get changeInEstimateTotal {
    final edited = editedItem;
    if (edited == null) return null;
    return (_toCents(lineTotal) - _toCents(edited.itemTotalCost)) / 100;
  }

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
    Object? rate = _unset,
    RateStatus? rateStatus,
    bool? isValid,
    Map<MaterialFormField, MaterialFieldError>? fieldErrors,
    bool? hasUnsavedChanges,
    Object? editedItem = _unset,
  }) {
    return MaterialCostFormData(
      itemName: itemName ?? this.itemName,
      quantity: quantity == _unset ? this.quantity : quantity as double?,
      unit: unit == _unset ? this.unit : unit as Unit?,
      rate: rate == _unset ? this.rate : rate as double?,
      rateStatus: rateStatus ?? this.rateStatus,
      isValid: isValid ?? this.isValid,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      editedItem: editedItem == _unset
          ? this.editedItem
          : editedItem as MaterialCostItem?,
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
    hasUnsavedChanges,
    editedItem,
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

  /// The cost item as saved by [CostItemRepository.createCostItem], or by
  /// [CostItemRepository.updateCostItem] when the form edited a line.
  final CostItem createdItem;
}

/// State when saving or deleting the cost item failed. The form keeps every
/// value so the user can try again.
class MaterialCostFormFailure extends MaterialCostFormState {
  const MaterialCostFormFailure(
    this.data,
    this.failure, {
    this.whileDeleting = false,
  });

  /// The form data as it was when saving failed.
  @override
  final MaterialCostFormData data;

  /// The failure returned by the repository.
  final Failure failure;

  /// Whether the failed action was deleting the line, not saving it.
  final bool whileDeleting;
}

/// State once the line this form edited was deleted from the estimate.
class MaterialCostFormDeleted extends MaterialCostFormState {
  const MaterialCostFormDeleted(this.data);

  /// The form data as it was when the line was deleted.
  @override
  final MaterialCostFormData data;
}

int _toCents(double amount) => (amount * 100).round();

const Object _unset = Object();
