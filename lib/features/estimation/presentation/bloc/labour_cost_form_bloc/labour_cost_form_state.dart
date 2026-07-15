part of 'labour_cost_form_bloc.dart';

/// Base sealed class for all labour cost form states.
sealed class LabourCostFormState {
  const LabourCostFormState();
}

/// Initial state before the user has interacted with the form.
class LabourCostFormInitial extends LabourCostFormState {
  const LabourCostFormInitial();
}

/// State while the user is filling in the labour cost form.
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

// TODO(CA-294): add LabourCostFormSubmitting, LabourCostFormSuccess, LabourCostFormFailure states

const Object _keep = Object();
