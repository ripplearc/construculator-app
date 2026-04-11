import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// Factory for creating test data for cost estimation logs.
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
      DatabaseConstants.activityDetailsColumn: activityDetails ?? const {},
      DatabaseConstants.loggedAtColumn: loggedAt ?? '2025-02-25T10:00:00.000Z',
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
        loggedAt: '2025-02-${(i + 1).toString().padLeft(2, '0')}T10:00:00.000Z',
      ),
    );
  }
}
