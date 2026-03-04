import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Remote implementation of the project repository.
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectDataSource _projectDataSource;
  final SupabaseWrapper _supabaseWrapper;
  final Clock _clock;
  static final _logger = AppLogger().tag('ProjectRepositoryImpl');

  ProjectRepositoryImpl({
    required ProjectDataSource projectDataSource,
    required SupabaseWrapper supabaseWrapper,
    Clock? clock,
  }) : _projectDataSource = projectDataSource,
       _supabaseWrapper = supabaseWrapper,
       _clock = clock ?? Modular.get<Clock>();

  @override
  Future<Project> getProject(String id) async {
    try {
      // TODO: https://ripplearc.youtrack.cloud/issue/CA-162/Dashboard-Create-Project-Repository
      return Project(
        id: id,
        projectName: 'Sample Construction Project',
        description: 'A sample construction project for testing purposes',
        creatorUserId: 'user_123',
        owningCompanyId: 'company_456',
        exportFolderLink: 'https://drive.google.com/sample-folder',
        exportStorageProvider: StorageProvider.googleDrive,
        createdAt: _clock.now(),
        updatedAt: _clock.now(),
        status: ProjectStatus.active,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting project by id: $id, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<List<Project>> getProjects() async {
    try {
      final userId = _supabaseWrapper.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final ownedProjects = await _projectDataSource.getOwnedProjects(userId);
      final sharedProjects = await _projectDataSource.getSharedProjects(userId);

      final projectsById = <String, Project>{};
      for (final projectDto in [...ownedProjects, ...sharedProjects]) {
        final project = projectDto.toDomain();
        projectsById[project.id] = project;
      }

      final projects = projectsById.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return projects;
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting accessible projects: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }
}
