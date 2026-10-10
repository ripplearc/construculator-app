import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// Factory for creating test data for cost estimation logs.
///
/// The server stores `logged_at` in UTC and the app shows it in the phone's
/// time zone. Default times are built from a local 10:00 AM so every
/// screenshot shows the same time on any machine.
class LogTestDataFactory {
  static Map<String, dynamic> createLogData({
    required String id,
    required String estimateId,
    required String activity,
    Map<String, dynamic>? activityDetails,
    String? userId,
    String? firstName,
    String? lastName,
    String? professionalRole,
    String? loggedAt,
  }) {
    final userDto = UserProfileDto(
      id: userId ?? 'user-default',
      credentialId: 'cred-default',
      firstName: firstName ?? 'John',
      lastName: lastName ?? 'Doe',
      professionalRole: professionalRole ?? 'Engineer',
      profilePhotoUrl: null,
    );

    return {
      DatabaseConstants.idColumn: id,
      DatabaseConstants.estimateIdColumn: estimateId,
      DatabaseConstants.activityColumn: activity,
      DatabaseConstants.userColumn: userDto.toJson(),
      DatabaseConstants.detailsColumn: activityDetails ?? const {},
      DatabaseConstants.loggedAtColumn:
          loggedAt ?? DateTime(2025, 2, 25, 10).toUtc().toIso8601String(),
    };
  }

  static List<Map<String, dynamic>> createLogDataList({
    required int count,
    required String estimateId,
    String activityType = 'costEstimationCreated',
  }) {
    return List.generate(
      count,
      (i) => createLogData(
        id: 'log-$i',
        estimateId: estimateId,
        activity: activityType,
        loggedAt: DateTime(2025, 2, i + 1, 10).toUtc().toIso8601String(),
      ),
    );
  }
}
