import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Remote implementation of the project repository.
///
/// Delegates data operations to the [ProjectDataSource] to maintain
/// separation between data access logic and domain orchestration.
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectDataSource _dataSource;

  ProjectRepositoryImpl({required ProjectDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Project> getProject(String id) async {
    // TODO: https://ripplearc.youtrack.cloud/issue/CA-162/Dashboard-Create-Project-Repository
    return Project(
      id: id,
      projectName: 'Sample Construction Project',
      description: 'A sample construction project for testing purposes',
      creatorUserId: 'user_123',
      owningCompanyId: 'company_456',
      exportFolderLink: 'https://drive.google.com/sample-folder',
      exportStorageProvider: StorageProvider.googleDrive,
      createdAt: Modular.get<Clock>().now(),
      updatedAt: Modular.get<Clock>().now(),
      status: ProjectStatus.active,
    );
  }

  @override
  Future<bool> hasPermission({
    required String projectId,
    required String permissionKey,
    required String userCredentialId,
  }) async {
    return _dataSource.hasPermission(
      projectId: projectId,
      permissionKey: permissionKey,
      userCredentialId: userCredentialId,
    );
  }
}
