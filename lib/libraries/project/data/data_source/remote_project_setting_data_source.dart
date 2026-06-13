import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:stack_trace/stack_trace.dart';

/// Remote data source for reading and mutating a single project's settings.
///
/// This layer talks directly to Supabase and throws low-level exceptions that
/// higher layers map into project failures.
class RemoteProjectSettingDataSource implements ProjectSettingDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteProjectSettingDataSource');

  /// Creates a remote project setting data source.
  const RemoteProjectSettingDataSource({
    required SupabaseWrapper supabaseWrapper,
  }) : _supabaseWrapper = supabaseWrapper;

  /// Creates a new project row from [projectDto] and returns the persisted row.
  ///
  /// Throws on network or database errors.
  @override
  Future<ProjectDto> createProject(ProjectDto projectDto) async {
    try {
      _logger.debug('Creating project with name: ${projectDto.projectName}');

      final data = <String, dynamic>{
        DatabaseConstants.projectNameColumn: projectDto.projectName,
        DatabaseConstants.descriptionColumn: projectDto.description,
        DatabaseConstants.creatorUserIdColumn: projectDto.creatorUserId,
        DatabaseConstants.owningCompanyIdColumn: projectDto.owningCompanyId,
        DatabaseConstants.exportFolderLinkColumn: projectDto.exportFolderLink,
        DatabaseConstants.exportStorageProviderColumn:
            projectDto.exportStorageProvider,
        DatabaseConstants.statusColumn: projectDto.status.name,
      };

      final result = await _supabaseWrapper.insert(
        table: DatabaseConstants.projectsTable,
        data: data,
      );

      return ProjectDto.fromJson(result);
    } catch (error, stackTrace) {
      _logger.warning(
        'Error while creating project: $error',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Fetches a single project setting row by [projectId].
  ///
  /// Throws [NotFoundException] when the project does not exist and rethrows
  /// unexpected Supabase or parsing errors.
  @override
  Future<ProjectDto> fetchProjectSetting(String projectId) async {
    try {
      _logger.debug('Getting project setting for projectId: $projectId');

      final row = await _supabaseWrapper.selectSingle(
        table: DatabaseConstants.projectsTable,
        filterColumn: DatabaseConstants.idColumn,
        filterValue: projectId,
      );

      if (row == null) {
        _logger.warning('Project not found for projectId: $projectId');
        throw NotFoundException(
          Trace.current(),
          Exception('Project not found for id: $projectId'),
        );
      }

      return ProjectDto.fromJson(row);
    } on NotFoundException {
      rethrow; // Prevents double-logging in the catch below.
    } catch (error, stackTrace) {
      _logger.warning(
        'Error while getting project setting for projectId: $projectId, error: $error',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Persists the editable project settings in remote storage.
  ///
  /// Returns the updated project row as stored remotely and rethrows
  /// unexpected Supabase or parsing errors.
  @override
  Future<ProjectDto> updateProject(ProjectDto projectDto) async {
    try {
      _logger.debug('Updating project with id: ${projectDto.id}');

      // Editable columns are always sent (including nulls) so the edit form
      // can clear an optional field. project_name is NOT NULL, so it is always set.
      // updated_at is omitted because it is managed server-side by a DB trigger.
      final data = <String, dynamic>{
        DatabaseConstants.projectNameColumn: projectDto.projectName,
        DatabaseConstants.descriptionColumn: projectDto.description,
        DatabaseConstants.exportFolderLinkColumn: projectDto.exportFolderLink,
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
      _logger.warning(
        'Error while updating project with id: ${projectDto.id}, error: $error',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes the project row identified by [projectId].
  ///
  /// Throws on unexpected Supabase errors.
  @override
  Future<void> deleteProject(String projectId) async {
    try {
      _logger.debug('Deleting project with id: $projectId');

      // Hard remote delete by id. Offline-queued / soft deletion will be
      // handled by the local data source.
      // Note: Supabase DELETE is a no-op for non-existent rows — callers that
      // need to distinguish "deleted" vs "never existed" must check rows-affected
      // at the repository layer.
      // TODO: https://ripplearc.youtrack.cloud/issue/CA-262
      await _supabaseWrapper.delete(
        table: DatabaseConstants.projectsTable,
        filterColumn: DatabaseConstants.idColumn,
        filterValue: projectId,
      );
    } catch (error, stackTrace) {
      _logger.warning(
        'Error while deleting project with id: $projectId, error: $error',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

}
