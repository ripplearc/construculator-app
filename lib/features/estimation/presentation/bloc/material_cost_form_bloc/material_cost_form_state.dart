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

class MaterialCostFormSubmitting extends MaterialCostFormState {
  const MaterialCostFormSubmitting();
}

class MaterialCostFormSuccess extends MaterialCostFormState {
  const MaterialCostFormSuccess({required this.item});

  final CostItem item;
}

class MaterialCostFormFailure extends MaterialCostFormState {
  const MaterialCostFormFailure({required this.failure, this.materialType = ''});

  final Failure failure;
  final String materialType;
}

// Sentinel to distinguish "not provided" from null in copyWith.
const Object _keep = Object();
