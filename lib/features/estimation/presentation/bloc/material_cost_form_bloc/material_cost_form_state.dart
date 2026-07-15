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
