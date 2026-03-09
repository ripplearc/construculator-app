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

  /// Unknown activity type
  ///
  /// Used when the client receives an activity type from the server that
  /// it doesn't recognize. This prevents crashes when the server adds new
  /// activity types before the client is updated.
  unknown,
}

/// Extension methods for CostEstimationActivityType
extension CostEstimationActivityTypeExtension on CostEstimationActivityType {
  /// Converts the enum to a string representation for storage.
  ///
  /// Converts to snake_case to match the database enum format.
  /// For example: `CostEstimationActivityType.costEstimationCreated`
  /// becomes `'cost_estimation_created'`.
  String toJson() {
    return _toSnakeCase(name);
  }

  /// Creates a CostEstimationActivityType from a string.
  ///
  /// Accepts both snake_case (database format) and camelCase strings.
  /// Returns [CostEstimationActivityType.unknown] for unrecognized values
  /// instead of throwing an exception. This ensures that the client remains
  /// functional when the server adds new activity types.
  static CostEstimationActivityType fromJson(String value) {
    final camelCaseValue = _toCamelCase(value);

    return CostEstimationActivityType.values.firstWhere(
      (e) => e.name == camelCaseValue,
      orElse: () => CostEstimationActivityType.unknown,
    );
  }

  static String _toSnakeCase(String camelCase) {
    return camelCase.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
      final matched = match.group(0);
      return matched != null ? '_${matched.toLowerCase()}' : '';
    });
  }

  static String _toCamelCase(String snakeCase) {
    return snakeCase.replaceAllMapped(RegExp(r'_([a-z])'), (match) {
      final matched = match.group(1);
      return matched != null ? matched.toUpperCase() : '';
    });
  }
}
