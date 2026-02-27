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

  /// Additional details specific to the activity type
  ///
  /// The structure of this map varies based on the activity type.
  /// See activity type documentation for specific field definitions.
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
