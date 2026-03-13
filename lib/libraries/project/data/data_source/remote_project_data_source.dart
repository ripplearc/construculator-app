import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:rxdart/rxdart.dart';

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

      final projectRows = await _supabaseWrapper.selectWhereIn(
        table: DatabaseConstants.projectsTable,
        filterColumn: DatabaseConstants.idColumn,
        filterValues: projectIds,
      );

      return projectRows.map(ProjectDto.fromJson).toList();
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting shared projects for userId: $userId, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Stream<void> watchProjectChanges(String userId) {
    final ownedProjectsStream = _supabaseWrapper
        .watchTableFiltered(
          table: DatabaseConstants.projectsTable,
          primaryKey: const [DatabaseConstants.idColumn],
          filterColumn: DatabaseConstants.creatorUserIdColumn,
          filterValue: userId,
        )
        .map((_) {});

    final sharedMembershipsStream = _supabaseWrapper
        .watchTableFiltered(
          table: DatabaseConstants.projectMembersTable,
          primaryKey: const [DatabaseConstants.idColumn],
          filterColumn: DatabaseConstants.userIdColumn,
          filterValue: userId,
        )
        .map((_) {});

    return MergeStream<void>([
      ownedProjectsStream,
      sharedMembershipsStream,
    ]).doOnError((Object error, StackTrace stackTrace) {
      _logger.error(
        'Error while watching project changes for userId: $userId, error: $error',
        stackTrace.toString(),
      );
    });
  }
}
