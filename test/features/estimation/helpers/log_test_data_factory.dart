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
    return {
      DatabaseConstants.idColumn: id,
      DatabaseConstants.estimateIdColumn: estimateId,
      DatabaseConstants.activityColumn: activity,
      DatabaseConstants.userColumn: {
        DatabaseConstants.idColumn: userId ?? 'user-default',
        'credential_id': 'cred-default',
        'first_name': firstName ?? 'John',
        'last_name': lastName ?? 'Doe',
        'professional_role': professionalRole ?? 'Engineer',
        'profile_photo_url': null,
      },
      DatabaseConstants.activityDetailsColumn: activityDetails ?? const {},
      DatabaseConstants.loggedAtColumn:
          loggedAt ?? '2025-02-25T10:00:00.000Z',
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
