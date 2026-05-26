import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stack_trace/stack_trace.dart';

class RemoteProjectSettingDataSource implements ProjectSettingDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteProjectSettingDataSource');

  const RemoteProjectSettingDataSource({
    required SupabaseWrapper supabaseWrapper,
  }) : _supabaseWrapper = supabaseWrapper;

  @override
  Future<ProjectDto> getProjectSetting(String projectId) async {
    try {
      _logger.debug('Getting project setting for projectId: $projectId');

      final row = await _supabaseWrapper.selectSingle(
        table: DatabaseConstants.projectsTable,
        filterColumn: DatabaseConstants.idColumn,
        filterValue: projectId,
      );

      if (row == null) {
        throw ServerException(
          Trace.current(),
          Exception('Project not found for id: $projectId'),
        );
      }

      return ProjectDto.fromJson(row);
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting project setting for projectId: $projectId, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<ProjectDto> updateProject(ProjectDto projectDto) async {
    try {
      _logger.debug('Updating project with id: ${projectDto.id}');

      final data = <String, dynamic>{
        DatabaseConstants.projectNameColumn: projectDto.projectName,
        if (projectDto.description != null)
          DatabaseConstants.descriptionColumn: projectDto.description,
        if (projectDto.exportFolderLink != null)
          DatabaseConstants.exportFolderLinkColumn: projectDto.exportFolderLink,
        if (projectDto.exportStorageProvider != null)
          DatabaseConstants.exportStorageProviderColumn:
              projectDto.exportStorageProvider,
      };

      final result = await _supabaseWrapper.update(
        table: DatabaseConstants.projectsTable,
        data: data,
        filterColumn: DatabaseConstants.idColumn,
        filterValue: projectDto.id,
      );

      return ProjectDto.fromJson(result);
    } catch (error, stackTrace) {
      _logger.error(
        'Error while updating project with id: ${projectDto.id}, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    try {
      _logger.debug('Deleting project with id: $projectId');

      await _supabaseWrapper.deleteMatch(
        table: DatabaseConstants.projectsTable,
        filters: {DatabaseConstants.idColumn: projectId},
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Error while deleting project with id: $projectId, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Stream<void> watchProjectChanges(String projectId) {
    return _supabaseWrapper
        .watchTableFiltered(
          table: DatabaseConstants.projectsTable,
          primaryKey: const [DatabaseConstants.idColumn],
          filterColumn: DatabaseConstants.idColumn,
          filterValue: projectId,
        )
        .map((_) {})
        .doOnError((Object error, StackTrace stackTrace) {
          _logger.error(
            'Error while watching project changes for projectId: $projectId, error: $error',
            stackTrace.toString(),
          );
        });
  }
}
