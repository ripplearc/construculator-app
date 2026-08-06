part of 'equipment_cost_form_bloc.dart';

/// Base sealed class for all equipment cost form states.
sealed class EquipmentCostFormState {
  const EquipmentCostFormState();
}

/// Initial state before the user has interacted with the form.
class EquipmentCostFormInitial extends EquipmentCostFormState {
  const EquipmentCostFormInitial();
}

/// State while the user is filling in the equipment cost form.
class EquipmentCostFormEditing extends EquipmentCostFormState {
  const EquipmentCostFormEditing({
    this.equipmentType = '',
    this.itemTypeError,
    this.unitPrice,
    this.unitPriceError,
  });

  /// The equipment type value entered by the user.
  final String equipmentType;

  /// Validation error key for the item type field, or null when valid.
  final String? itemTypeError;
  final double? unitPrice;
  final String? unitPriceError;

  /// Whether the item type field contains a non-empty value.
  bool get isItemTypeValid => equipmentType.trim().isNotEmpty;
  bool get isUnitPriceValid => (unitPrice ?? 0) > 0;
  bool get isValid => isItemTypeValid && isUnitPriceValid;

  /// Returns a copy of this state with the given fields replaced.
  EquipmentCostFormEditing copyWith({
    String? equipmentType,
    Object? itemTypeError = _keep,
    Object? unitPrice = _keep,
    Object? unitPriceError = _keep,
  }) {
    return EquipmentCostFormEditing(
      equipmentType: equipmentType ?? this.equipmentType,
      itemTypeError: itemTypeError == _keep
          ? this.itemTypeError
          : itemTypeError as String?,
      unitPrice: unitPrice == _keep ? this.unitPrice : unitPrice as double?,
      unitPriceError: unitPriceError == _keep
          ? this.unitPriceError
          : unitPriceError as String?,
    );
  }
}

// TODO(CA-294): add EquipmentCostFormSubmitting, EquipmentCostFormSuccess, EquipmentCostFormFailure states

const Object _keep = Object();
