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
  const EquipmentCostFormEditing({this.equipmentType = '', this.itemTypeError});

  final String equipmentType;
  final String? itemTypeError;

  bool get isItemTypeValid => equipmentType.trim().isNotEmpty;

  EquipmentCostFormEditing copyWith({
    String? equipmentType,
    Object? itemTypeError = _keep,
  }) {
    return EquipmentCostFormEditing(
      equipmentType: equipmentType ?? this.equipmentType,
      itemTypeError: itemTypeError == _keep
          ? this.itemTypeError
          : itemTypeError as String?,
    );
  }
}

// TODO(CA-294): add EquipmentCostFormSubmitting, EquipmentCostFormSuccess, EquipmentCostFormFailure states

const Object _keep = Object();
