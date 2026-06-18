import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/owner/data/data_source/interfaces/owner_data_source.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Supabase-backed implementation of [OwnerDataSource].
///
/// Delegates to the [DatabaseConstants.projectOwnersRpcFunction] RPC, which
/// returns user-profile-shaped rows for the owners (project creators) the
/// authenticated caller can access. The caller identity is derived from the
/// Supabase auth session JWT, so no explicit user id param is forwarded.
class RemoteOwnerDataSource implements OwnerDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteOwnerDataSource');

  /// Creates a [RemoteOwnerDataSource].
  const RemoteOwnerDataSource({required SupabaseWrapper supabaseWrapper})
    : _supabaseWrapper = supabaseWrapper;

  @override
  Future<List<UserProfileDto>> fetchOwners() async {
    _logger.debug('Fetching project owners');

    try {
      final rows = await _supabaseWrapper.rpc<List<dynamic>>(
        DatabaseConstants.projectOwnersRpcFunction,
      );

      return rows
          .whereType<Map<String, dynamic>>()
          .map(UserProfileDto.fromJson)
          .toList();
    } catch (error, stackTrace) {
      _logger.error(
        'Error while fetching project owners, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }
}
