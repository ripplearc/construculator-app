/// Represents the type of activity performed on a cost estimation
///
/// Each activity type corresponds to a specific action that can be
/// tracked in the estimation's activity log.
///
/// Wire counterpart: `cost_estimation_activity_type_enum` in
/// construculator-backend (`supabase/schemas/_types/enums.sql`), the type of
/// the `NOT NULL` `cost_estimate_logs.activity` column.
///
/// [CostEstimationActivityTypeExtension.toJson] is snake_case of the member
/// name, so the names below *are* the wire contract — renaming one is a
/// breaking change that needs a matching `ALTER TYPE` migration. The
/// Estimation-v2 kinds are not in the backend enum yet; they follow its
/// `<entity>_<verb>` convention so the migration that adds them can use these
/// values verbatim.
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

  /// The estimation was sent to a recipient
  ///
  /// `activityDetails` carries the recipient's `recipientName`, a string,
  /// which the title names. A send to several people logs one row each.
  costEstimationSent,

  /// A send to a recipient failed: the server confirmed it did not go out
  ///
  /// `activityDetails` carries `recipientName`, as [costEstimationSent] does.
  /// A send that works on a later try logs its own [costEstimationSent].
  costEstimationSendFailed,

  /// A sent estimation's link was opened for the first time
  ///
  /// Logged once per link. The row says whose link it was, never who
  /// opened it.
  costEstimationOpened,

  /// A sent estimation was revoked by the sender
  costEstimationRevoked,

  /// The sender recorded the recipient's approval of a sent estimation
  ///
  /// The recipient replies by phone or text, and the sender records it on
  /// the Send screen, so the row's user is the sender.
  costEstimationApproved,

  /// The sender recorded that the recipient asked for changes
  ///
  /// Recorded by the sender, as [costEstimationApproved] is.
  /// `activityDetails` carries the recipient's `reason`, a string.
  costEstimationChangesRequested,

  /// The estimation's PDF was handed to another app from the share sheet
  ///
  /// Logged only once the sender picks an app, and it cannot tell whether
  /// the PDF arrived.
  costEstimationPdfShared,

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
