import 'package:construculator/features/dashboard/data/data_source/interfaces/project_search_data_source.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

class RemoteProjectSearchDataSource implements ProjectSearchDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteProjectSearchDataSource');

  const RemoteProjectSearchDataSource({
    required SupabaseWrapper supabaseWrapper,
  }) : _supabaseWrapper = supabaseWrapper;

  @override
  Future<List<ProjectDto>> searchProjects(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      _logger.debug('Searching projects for query: $query');

      final response = await _supabaseWrapper.rpc<Map<String, dynamic>>(
        DatabaseConstants.globalSearchRpcFunction,
        params: {
          'query': query,
          'scope': 'dashboard',
          'offset': 0,
          'limit': 20,
          'filter_by_tag': null,
          'filter_by_date': null,
          'filter_by_owner': null,
        },
      );

      final projectsRaw = response['projects'] as List<dynamic>? ?? [];
      return projectsRaw
          .whereType<Map<String, dynamic>>()
          .map(ProjectDto.fromJson)
          .toList();
    } catch (error, stackTrace) {
      _logger.error(
        'Error searching projects for query: $query, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }
}
