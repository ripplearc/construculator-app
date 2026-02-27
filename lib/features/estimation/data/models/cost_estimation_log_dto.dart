import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for CostEstimationLog entity.
///
/// This DTO represents the serialized form of a cost estimation log entry
/// as it appears in the database. It handles the conversion between the
/// database JSON format and the domain entity structure.
///
/// The DTO stores the activity type as a string and the user as a nested
/// JSON object, while the domain entity uses proper enum and entity types.
class CostEstimationLogDto extends Equatable {
  /// Unique identifier for the log entry.
  final String id;

  /// ID of the estimation this log belongs to.
  final String estimateId;

  /// Type of activity that was performed (stored as string).
  final String activity;

  /// User who performed the activity (stored as nested JSON).
  final Map<String, dynamic> user;

  /// Additional details specific to the activity type.
  final Map<String, dynamic> activityDetails;

  /// ISO 8601 timestamp when the activity was logged.
  final String loggedAt;

  const CostEstimationLogDto({
    required this.id,
    required this.estimateId,
    required this.activity,
    required this.user,
    required this.activityDetails,
    required this.loggedAt,
  });

  /// Creates a [CostEstimationLogDto] from a JSON map.
  ///
  /// This factory method handles the conversion from the database JSON format
  /// to the DTO structure, mapping snake_case JSON keys to camelCase Dart properties.
  factory CostEstimationLogDto.fromJson(Map<String, dynamic> json) {
    return CostEstimationLogDto(
      id: json['id'] as String,
      estimateId: json['estimate_id'] as String,
      activity: json['activity'] as String,
      user: json['user'] as Map<String, dynamic>,
      activityDetails: json['activity_details'] as Map<String, dynamic>,
      loggedAt: json['logged_at'] as String,
    );
  }

  /// Converts this DTO to a JSON map.
  ///
  /// This method converts the DTO back to the database JSON format,
  /// mapping camelCase Dart properties to snake_case JSON keys.
  Map<String, dynamic> toJson() => {
    'id': id,
    'estimate_id': estimateId,
    'activity': activity,
    'user': user,
    'activity_details': activityDetails,
    'logged_at': loggedAt,
  };

  /// Converts this DTO to a domain [CostEstimationLog] entity.
  ///
  /// This method performs the transformation from the DTO structure to the
  /// domain entity structure. It:
  /// - Converts string activity type to [CostEstimationActivityType] enum
  /// - Converts nested user JSON to [UserProfile] entity
  /// - Parses ISO 8601 timestamp string to [DateTime] object
  ///
  /// Throws [FormatException] if timestamp string is invalid.
  /// Throws [ArgumentError] if activity type string is unrecognized.
  CostEstimationLog toDomain() {
    return CostEstimationLog(
      id: id,
      estimateId: estimateId,
      activity: CostEstimationActivityTypeExtension.fromJson(activity),
      user: UserProfileDto.fromJson(user).toDomain(),
      activityDetails: activityDetails,
      loggedAt: DateTime.parse(loggedAt),
    );
  }

  /// Creates a [CostEstimationLogDto] from a domain [CostEstimationLog] entity.
  ///
  /// This method converts the domain entity back to the DTO structure for
  /// database storage or API transmission. It:
  /// - Converts [CostEstimationActivityType] enum to string
  /// - Converts [UserProfile] entity to nested JSON object
  /// - Formats [DateTime] to ISO 8601 timestamp string
  factory CostEstimationLogDto.fromDomain(CostEstimationLog log) {
    return CostEstimationLogDto(
      id: log.id,
      estimateId: log.estimateId,
      activity: log.activity.toJson(),
      user: UserProfileDto.fromDomain(log.user).toJson(),
      activityDetails: log.activityDetails,
      loggedAt: log.loggedAt.toIso8601String(),
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
