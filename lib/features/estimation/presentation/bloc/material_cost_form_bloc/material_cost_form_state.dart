part of 'material_cost_form_bloc.dart';

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
  const MaterialCostFormEditing({
    this.materialType = '',
    this.itemTypeError,
    this.selectedUnit,
    this.unitError,
  });

  /// The material type value entered by the user.
  final String materialType;

  /// Validation error key for the item type field, or null when valid.
  final String? itemTypeError;
  final Unit? selectedUnit;
  final String? unitError;

  /// Whether the item type field contains a non-empty value.
  bool get isItemTypeValid => materialType.trim().isNotEmpty;
  bool get isUnitValid => selectedUnit != null;

  /// Returns a copy of this state with the given fields replaced.
  MaterialCostFormEditing copyWith({
    String? materialType,
    Object? itemTypeError = _keep,
    Object? selectedUnit = _keep,
    Object? unitError = _keep,
  }) {
    return MaterialCostFormEditing(
      materialType: materialType ?? this.materialType,
      itemTypeError: itemTypeError == _keep
          ? this.itemTypeError
          : itemTypeError as String?,
      selectedUnit: selectedUnit == _keep
          ? this.selectedUnit
          : selectedUnit as Unit?,
      unitError: unitError == _keep ? this.unitError : unitError as String?,
    );
  }
}

// TODO(CA-294): add MaterialCostFormSubmitting, MaterialCostFormSuccess, MaterialCostFormFailure states

const Object _keep = Object();
