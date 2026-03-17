import 'package:equatable/equatable.dart';
import 'cost_estimation_activity_type.dart';
import '../../../../libraries/auth/domain/entities/user_profile_entity.dart';

/// Represents a log entry for a cost estimation activity
///
/// Each log captures the 'Who', 'What', and 'When' of an activity:
/// - Who: The user who performed the action
/// - What: The activity type and its details
/// - When: The timestamp of when the activity occurred
class CostEstimationLog extends Equatable {
  /// Unique identifier for the log entry
  final String id;

  /// ID of the estimation this log belongs to
  final String estimateId;

  /// Type of activity that was performed
  final CostEstimationActivityType activity;

  /// User who performed the activity
  final UserProfile user;

  /// Additional details specific to the activity type.
  ///
  /// The structure of this map varies based on the activity type.
  /// For complete specification, see:
  /// https://docs.google.com/document/d/1MHn-LanxVJ96-HSe47C9Km0evtkPcyQDw9eDzFD60AA/edit?tab=t.m4ek8adycklb#bookmark=id.d9tpu71yhacg
  ///
  /// **COST_ESTIMATION_CREATED**:
  /// ```json
  /// {
  ///   "name": "string",
  ///   "description": "string"
  /// }
  /// ```
  ///
  /// **COST_ESTIMATION_RENAMED**:
  /// ```json
  /// {
  ///   "oldName": "string",
  ///   "newName": "string"
  /// }
  /// ```
  ///
  /// **COST_ESTIMATION_EXPORTED**:
  /// ```json
  /// {
  ///   "format": "string",
  ///   "destination": "string"
  /// }
  /// ```
  ///
  /// **COST_ITEM_ADDED**:
  /// ```json
  /// {
  ///   "costItemId": "string",
  ///   "costItemType": "string",
  ///   "description": "string"
  /// }
  /// ```
  ///
  /// **COST_ITEM_EDITED**:
  /// ```json
  /// {
  ///   "costItemId": "string",
  ///   "costItemType": "string",
  ///   "editedFields": {
  ///     "fieldName": {
  ///       "oldValue": "any",
  ///       "newValue": "any"
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// **COST_ITEM_REMOVED**:
  /// ```json
  /// {
  ///   "costItemId": "string",
  ///   "costItemType": "string"
  /// }
  /// ```
  ///
  /// **COST_ITEM_DUPLICATED**:
  /// ```json
  /// {
  ///   "originalCostItemId": "string",
  ///   "costItemType": "string",
  ///   "newCostItemId": "string"
  /// }
  /// ```
  ///
  /// **TASK_ASSIGNED**:
  /// ```json
  /// {
  ///   "costItemId": "string",
  ///   "assigneeEmail": "string"
  /// }
  /// ```
  ///
  /// **TASK_UNASSIGNED**:
  /// ```json
  /// {
  ///   "costItemId": "string",
  ///   "oldAssigneeEmail": "string"
  /// }
  /// ```
  ///
  /// **COST_FILE_UPLOADED**:
  /// ```json
  /// {
  ///   "costFileId": "string",
  ///   "fileName": "string",
  ///   "fileSize": "number",
  ///   "fileType": "string"
  /// }
  /// ```
  ///
  /// **COST_FILE_DELETED**:
  /// ```json
  /// {
  ///   "costFileId": "string",
  ///   "fileName": "string",
  ///   "fileSize": "number",
  ///   "fileType": "string"
  /// }
  /// ```
  ///
  /// **ATTACHMENT_ADDED**:
  /// ```json
  /// {
  ///   "attachmentId": "string",
  ///   "fileName": "string",
  ///   "fileSize": "string",
  ///   "fileType": "string",
  ///   "attachmentType": "string",
  ///   "documentCategory": "string"
  /// }
  /// ```
  ///
  /// **ATTACHMENT_REMOVED**:
  /// ```json
  /// {
  ///   "attachmentId": "string",
  ///   "fileName": "string",
  ///   "fileSize": "string",
  ///   "fileType": "string"
  /// }
  /// ```
  ///
  /// **Other activity types**: May have empty map `{}` if no additional details needed
  final Map<String, dynamic> activityDetails;

  /// Timestamp when the activity was logged
  final DateTime loggedAt;

  const CostEstimationLog({
    required this.id,
    required this.estimateId,
    required this.activity,
    required this.user,
    required this.activityDetails,
    required this.loggedAt,
  });

  /// Creates a copy of this log with the given fields replaced
  CostEstimationLog copyWith({
    String? id,
    String? estimateId,
    CostEstimationActivityType? activity,
    UserProfile? user,
    Map<String, dynamic>? activityDetails,
    DateTime? loggedAt,
  }) {
    return CostEstimationLog(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      activity: activity ?? this.activity,
      user: user ?? this.user,
      activityDetails: activityDetails ?? this.activityDetails,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    estimateId,
    activity,
    user,
    activityDetails,
    loggedAt,
  ];
}
