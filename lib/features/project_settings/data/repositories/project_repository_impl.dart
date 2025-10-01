import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';
import 'package:construculator/features/project_settings/domain/entities/enums.dart';
import 'package:construculator/features/project_settings/domain/repositories/project_repository.dart';

/// Remote implementation of the project repository.
class RemoteProjectRepository implements ProjectRepository {
  @override
  Future<Project> getProject(String id) async {
    // TODO: Remove dummy data and implement the actual remote data source
    return Project(
      id: id,
      projectName: 'Sample Construction Project',
      description: 'A sample construction project for testing purposes',
      creatorUserId: 'user_123',
      owningCompanyId: 'company_456',
      exportFolderLink: 'https://drive.google.com/sample-folder',
      exportStorageProvider: StorageProvider.googleDrive,
      createdAt: DateTime(2025, 10, 1, 10, 30),
      updatedAt: DateTime(2025, 10, 1, 10, 30),
      status: ProjectStatus.active,
    );
  }
}
