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

  /// The labour type value entered by the user.
  final String labourType;

  /// Validation error key for the item type field, or null when valid.
  final String? itemTypeError;

  /// Whether the item type field contains a non-empty value.
  bool get isItemTypeValid => labourType.trim().isNotEmpty;

  /// Returns a copy of this state with the given fields replaced.
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
