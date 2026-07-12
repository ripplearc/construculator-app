part of 'equipment_cost_form_bloc.dart';

sealed class EquipmentCostFormState {
  const EquipmentCostFormState();
}

class EquipmentCostFormInitial extends EquipmentCostFormState {
  const EquipmentCostFormInitial();
}

class EquipmentCostFormEditing extends EquipmentCostFormState {
  const EquipmentCostFormEditing({this.equipmentName = '', this.itemTypeError});

  final String equipmentName;
  final String? itemTypeError;

  bool get isItemTypeValid => equipmentName.trim().isNotEmpty;

  EquipmentCostFormEditing copyWith({
    String? equipmentName,
    Object? itemTypeError = _keep,
  }) {
    return EquipmentCostFormEditing(
      equipmentName: equipmentName ?? this.equipmentName,
      itemTypeError: itemTypeError == _keep
          ? this.itemTypeError
          : itemTypeError as String?,
    );
  }
}

// TODO(CA-294): add EquipmentCostFormSubmitting, EquipmentCostFormSuccess, EquipmentCostFormFailure states

const Object _keep = Object();
