import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

class RemoteProjectDataSource implements ProjectDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteProjectDataSource');

  const RemoteProjectDataSource({required SupabaseWrapper supabaseWrapper})
    : _supabaseWrapper = supabaseWrapper;

  @override
  Future<List<ProjectDto>> getOwnedProjects(String userId) async {
    try {
      _logger.debug('Getting owned projects for userId: $userId');

      final response = await _supabaseWrapper.select(
        table: DatabaseConstants.projectsTable,
        filterColumn: DatabaseConstants.creatorUserIdColumn,
        filterValue: userId,
      );

      return response.map(ProjectDto.fromJson).toList();
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting owned projects for userId: $userId, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<List<ProjectDto>> getSharedProjects(String userId) async {
    try {
      _logger.debug('Getting shared projects for userId: $userId');

      final memberships = await _supabaseWrapper.select(
        table: DatabaseConstants.projectMembersTable,
        filterColumn: DatabaseConstants.userIdColumn,
        filterValue: userId,
      );

      final projectIds = memberships
          .map((row) => row[DatabaseConstants.projectIdColumn] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      if (projectIds.isEmpty) {
        return [];
      }

      final projects = <ProjectDto>[];
      for (final projectId in projectIds) {
        final projectJson = await _supabaseWrapper.selectSingle(
          table: DatabaseConstants.projectsTable,
          filterColumn: DatabaseConstants.idColumn,
          filterValue: projectId,
        );
        if (projectJson != null) {
          projects.add(ProjectDto.fromJson(projectJson));
        }
      }

      return projects;
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting shared projects for userId: $userId, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }
}
