part of 'labour_cost_form_bloc.dart';

sealed class LabourCostFormState {
  const LabourCostFormState();
}

class LabourCostFormInitial extends LabourCostFormState {
  const LabourCostFormInitial();
}

class LabourCostFormEditing extends LabourCostFormState {
  const LabourCostFormEditing({this.labourType = '', this.itemTypeError});

  final String labourType;
  final String? itemTypeError;

  bool get isItemTypeValid => labourType.trim().isNotEmpty;

  LabourCostFormEditing copyWith({
    String? labourType,
    Object? itemTypeError = _keep,
  }) {
    return LabourCostFormEditing(
      labourType: labourType ?? this.labourType,
      itemTypeError: itemTypeError == _keep
          ? this.itemTypeError
          : itemTypeError as String?,
    );
  }
}

class LabourCostFormSubmitting extends LabourCostFormState {
  const LabourCostFormSubmitting();
}

class LabourCostFormSuccess extends LabourCostFormState {
  const LabourCostFormSuccess({required this.item});

  final CostItem item;
}

class LabourCostFormFailure extends LabourCostFormState {
  const LabourCostFormFailure({required this.failure, this.labourType = ''});

  final Failure failure;
  final String labourType;
}

const Object _keep = Object();
