part of 'material_cost_form_bloc.dart';

sealed class MaterialCostFormState {
  const MaterialCostFormState();
}

class MaterialCostFormInitial extends MaterialCostFormState {
  const MaterialCostFormInitial();
}

class MaterialCostFormEditing extends MaterialCostFormState {
  const MaterialCostFormEditing({this.materialType = '', this.itemTypeError});

  final String materialType;
  final String? itemTypeError;

  bool get isItemTypeValid => materialType.trim().isNotEmpty;

  MaterialCostFormEditing copyWith({
    String? materialType,
    Object? itemTypeError = _keep,
  }) {
    return MaterialCostFormEditing(
      materialType: materialType ?? this.materialType,
      itemTypeError: itemTypeError == _keep
          ? this.itemTypeError
          : itemTypeError as String?,
    );
  }
}

// TODO(CA-294): add MaterialCostFormSubmitting, MaterialCostFormSuccess, MaterialCostFormFailure states

const Object _keep = Object();
