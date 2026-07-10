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

class EquipmentCostFormSubmitting extends EquipmentCostFormState {
  const EquipmentCostFormSubmitting();
}

class EquipmentCostFormSuccess extends EquipmentCostFormState {
  const EquipmentCostFormSuccess({required this.item});

  final CostItem item;
}

class EquipmentCostFormFailure extends EquipmentCostFormState {
  const EquipmentCostFormFailure({
    required this.failure,
    this.equipmentName = '',
  });

  final Failure failure;
  final String equipmentName;
}

const Object _keep = Object();
