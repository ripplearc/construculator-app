/// Represents the type of activity performed on a cost estimation
///
/// Each activity type corresponds to a specific action that can be
/// tracked in the estimation's activity log.
enum CostEstimationActivityType {
  /// Estimation was created
  costEstimationCreated,

  /// Estimation was renamed
  costEstimationRenamed,

  /// Estimation was exported
  costEstimationExported,

  /// Estimation was locked
  costEstimationLocked,

  /// Estimation was unlocked
  costEstimationUnlocked,

  /// Estimation was deleted
  costEstimationDeleted,

  /// A cost item was added to the estimation
  costItemAdded,

  /// A cost item was edited
  costItemEdited,

  /// A cost item was removed from the estimation
  costItemRemoved,

  /// A cost item was duplicated
  costItemDuplicated,

  /// A task was assigned to a user
  taskAssigned,

  /// A task was unassigned from a user
  taskUnassigned,

  /// A cost file was uploaded
  costFileUploaded,

  /// A cost file was deleted
  costFileDeleted,

  /// An attachment was added
  attachmentAdded,

  /// An attachment was removed
  attachmentRemoved,
}

/// Extension methods for CostEstimationActivityType
extension CostEstimationActivityTypeExtension on CostEstimationActivityType {
  /// Converts the enum to a string representation for storage
  String toJson() {
    return name;
  }

  /// Creates a CostEstimationActivityType from a string
  static CostEstimationActivityType fromJson(String value) {
    return CostEstimationActivityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid activity type: $value'),
    );
  }
}
