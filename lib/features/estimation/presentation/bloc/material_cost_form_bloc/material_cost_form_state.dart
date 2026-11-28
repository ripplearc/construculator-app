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
  /// that quantity times rate, with waste, no longer fits the line total
  /// column.
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
    this.rate,
    this.rateStatus = RateStatus.missing,
    this.attachedPrice,
    this.wastePercent = newMaterialWastePercent,
    this.note,
    this.isValid = false,
    this.fieldErrors = const {},
    this.hasUnsavedChanges = false,
    this.editedItem,
    this.recalledRateId,
  });

  /// The material name entered by the user.
  final String itemName;

  /// The quantity entered by the user, or null while empty or unreadable.
  final double? quantity;

  /// The unit the quantity is counted in, or null when there is none yet.
  ///
  /// While it is empty, or was filled from memory and no quantity or rate is
  /// filled in, it takes the unit last used for the typed material name, and
  /// empties when that name has none. An attached price sets it to the
  /// price's unit. Once a unit is picked or a price is attached, or while a
  /// quantity or rate is filled in, a name change never replaces the unit
  /// shown.
  final Unit? unit;

  /// The price of one unit, or null while empty or unreadable.
  final double? rate;

  /// Confidence level of [rate].
  final RateStatus rateStatus;

  /// The saved price [rate] came from, or null when the rate was typed or is
  /// empty.
  final AttachedPrice? attachedPrice;

  /// The largest waste percentage the form accepts.
  static const double maxWastePercent = 100;

  /// The waste a brand-new material starts with.
  // TODO: [CA-1157] start a material picked from the cost file at that item's own waste. https://ripplearc.youtrack.cloud/issue/CA-1157
  static const double newMaterialWastePercent = 10;

  /// Extra material allowed for waste, from 0 to [maxWastePercent], or null
  /// while the field is empty. It opens at [newMaterialWastePercent]. Empty
  /// adds nothing, the same as 0, but is kept apart so it can show as a dash.
  final double? wastePercent;

  /// The note saved as the line's description, or null when there is none.
  final String? note;

  /// Whether [wastePercent] still holds the value suggested for a new line.
  bool get isWasteSuggested =>
      !isEditingExistingLine && wastePercent == newMaterialWastePercent;

  /// Whether name, quantity, unit and rate are all present and in range.
  final bool isValid;

  /// Validation error by field, present only for a value that was entered and
  /// cannot be used. An empty field never has an entry: the disabled Add
  /// button names what is missing.
  final Map<MaterialFormField, MaterialFieldError> fieldErrors;

  /// Whether any of name, quantity, unit, rate, waste or note differs from
  /// how the form opened. Typing a value and then restoring the original
  /// clears it.
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
  /// `null` when the form adds a new line, so there is nothing to compare,
  /// and while the quantity or the rate is missing, so a number being retyped
  /// does not show the whole line as removed.
  double? get changeInEstimateTotal {
    final edited = editedItem;
    if (edited == null || quantity == null || rate == null) return null;
    return (_toCents(lineTotal) - _toCents(edited.itemTotalCost)) / 100;
  }

  /// The id of the Your rates entry the name and rate came from, or null when
  /// the user typed them. Editing the name or the rate clears it, so adding
  /// the line marks the saved rate as used only while it is still the one
  /// picked.
  final String? recalledRateId;

  /// Quantity times rate plus [wasteAmount], or 0 while quantity or rate is
  /// missing or unusable.
  double get lineTotal => (_baseCents + _wasteCents) / 100;

  /// What [wastePercent] adds to quantity times rate, rounded to the cent.
  double get wasteAmount => _wasteCents / 100;

  double get _baseCents {
    final quantity = this.quantity;
    final rate = this.rate;
    if (quantity == null || rate == null) return 0;
    if (!quantity.isFinite || !rate.isFinite) return 0;
    return (quantity * (rate * 100).round()).roundToDouble();
  }

  double get _wasteCents =>
      (_baseCents * (wastePercent ?? 0) / 100).roundToDouble();

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
    Object? attachedPrice = _unset,
    Object? wastePercent = _unset,
    Object? note = _unset,
    bool? isValid,
    Map<MaterialFormField, MaterialFieldError>? fieldErrors,
    bool? hasUnsavedChanges,
    Object? editedItem = _unset,
    Object? recalledRateId = _unset,
  }) {
    return MaterialCostFormData(
      itemName: itemName ?? this.itemName,
      quantity: quantity == _unset ? this.quantity : quantity as double?,
      unit: unit == _unset ? this.unit : unit as Unit?,
      rate: rate == _unset ? this.rate : rate as double?,
      rateStatus: rateStatus ?? this.rateStatus,
      attachedPrice: attachedPrice == _unset
          ? this.attachedPrice
          : attachedPrice as AttachedPrice?,
      wastePercent: wastePercent == _unset
          ? this.wastePercent
          : wastePercent as double?,
      note: note == _unset ? this.note : note as String?,
      isValid: isValid ?? this.isValid,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      editedItem: editedItem == _unset
          ? this.editedItem
          : editedItem as MaterialCostItem?,
      recalledRateId: recalledRateId == _unset
          ? this.recalledRateId
          : recalledRateId as String?,
    );
  }

  @override
  List<Object?> get props => [
    itemName,
    quantity,
    unit,
    rate,
    rateStatus,
    attachedPrice,
    wastePercent,
    note,
    isValid,
    fieldErrors,
    hasUnsavedChanges,
    editedItem,
    recalledRateId,
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
  const MaterialCostFormSuccess(this.data, this.savedItem);

  /// The form data as it was when saved.
  @override
  final MaterialCostFormData data;

  /// The cost item as saved by [CostItemRepository.addCostItemOnPhone], or by
  /// [CostItemRepository.updateCostItem] when the form edited a line.
  final CostItem savedItem;
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
