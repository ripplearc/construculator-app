import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

class RemoteProjectDataSource implements ProjectDataSource {
  final SupabaseWrapper supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteProjectDataSource');

  RemoteProjectDataSource({required this.supabaseWrapper});

  @override
  Future<bool> hasPermission({
    required String projectId,
    required String permissionKey,
    required String userCredentialId,
  }) async {
    try {
      _logger.debug(
        'Checking permission "$permissionKey" for user: $userCredentialId '
        'on project: $projectId',
      );

      final result = await supabaseWrapper.rpc<bool>(
        DatabaseConstants.userHasProjectPermissionFunction,
        params: {
          'p_project_id': projectId,
          'p_permission_key': permissionKey,
          'p_user_credential_id': userCredentialId,
        },
      );

      _logger.debug(
        'Permission "$permissionKey" for user: $userCredentialId '
        'on project: $projectId => $result',
      );

      return result;
    } catch (e) {
      _logger.error(
        'Error checking permission "$permissionKey" for user: '
        '$userCredentialId on project: $projectId: $e',
      );
      rethrow;
    }
  }
}
