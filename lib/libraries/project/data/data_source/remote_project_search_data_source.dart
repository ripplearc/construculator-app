import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_search_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Remote implementation of [ProjectSearchDataSource] using Supabase.
///
/// Delegates to the [global_search] RPC with [scope] locked to [dashboard] and
/// extracts only the projects array from the response. All other result types
/// (estimations, members) are discarded.
///
/// [userId] is used only as an early-exit guard and is not forwarded in the
/// RPC params. The backend derives the caller identity from the Supabase
/// auth session JWT, so no explicit `user_id` param is needed.
class RemoteProjectSearchDataSource implements ProjectSearchDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteProjectSearchDataSource');

  /// Creates a [RemoteProjectSearchDataSource] with the given [supabaseWrapper].
  const RemoteProjectSearchDataSource({required SupabaseWrapper supabaseWrapper})
    : _supabaseWrapper = supabaseWrapper;

  @override
  Future<List<ProjectDto>> fetchProjectsBySearchQuery({
    required String userId,
    required String query,
    DateTime? filterByDate,
    String? filterByTag,
    String? filterByOwner,
  }) async {
    if (query.trim().isEmpty || userId.trim().isEmpty) {
      _logger.debug('Empty query or userId — skipping RPC call');
      return [];
    }

    try {
      _logger.debug('Searching projects for query: $query, userId: $userId');

      final response = await _supabaseWrapper.rpc<Map<String, dynamic>>(
        DatabaseConstants.globalSearchRpcFunction,
        params: {
          'query': query,
          'filter_by_tag': filterByTag,
          'filter_by_date': filterByDate?.toIso8601String(),
          'filter_by_owner': filterByOwner,
          'scope': DatabaseConstants.globalSearchDashboardScope,
          'offset': DatabaseConstants.globalSearchDefaultOffset,
          'limit': DatabaseConstants.globalSearchDefaultLimit,
        },
      );

      final projectsRaw = response['projects'] as List<dynamic>? ?? [];
      final projects = projectsRaw
          .whereType<Map<String, dynamic>>()
          .map(ProjectDto.fromJson)
          .toList();

      _logger.debug('Found ${projects.length} projects for query: $query');
      return projects;
    } on supabase.PostgrestException catch (error, stackTrace) {
      _logger.warning(
        'Supabase error while searching projects for query: $query, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    } catch (error, stackTrace) {
      _logger.error(
        'Unexpected error while searching projects for query: $query, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }
}
