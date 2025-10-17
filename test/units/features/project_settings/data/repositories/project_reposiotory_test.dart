import 'package:construculator/features/project_settings/data/repositories/project_repository_impl.dart';
import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';
import 'package:construculator/features/project_settings/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteProjectRepository', () {
    late RemoteProjectRepository repository;

    setUp(() {
      repository = RemoteProjectRepository();
    });

    group('getProject', () {
      test('should return dummy project data with correct structure', () async {
        // Arrange
        const projectId = 'test-project-123';

        // Act
        final result = await repository.getProject(projectId);

        // Assert
        expect(result, isA<Project>());
        expect(result.id, equals(projectId));
        expect(result.projectName, equals('Sample Construction Project'));
        expect(result.description, equals('A sample construction project for testing purposes'));
        expect(result.creatorUserId, equals('user_123'));
        expect(result.owningCompanyId, equals('company_456'));
        expect(result.exportFolderLink, equals('https://drive.google.com/sample-folder'));
        expect(result.exportStorageProvider, equals(StorageProvider.googleDrive));
        expect(result.status, equals(ProjectStatus.active));
        expect(result.createdAt, equals(DateTime(2025, 10, 1, 10, 30)));
        expect(result.updatedAt, equals(DateTime(2025, 10, 1, 10, 30)));
      });

      test('should return project with same dummy data regardless of input id', () async {
        // Arrange
        const projectId1 = 'different-id-1';
        const projectId2 = 'different-id-2';

        // Act
        final result1 = await repository.getProject(projectId1);
        final result2 = await repository.getProject(projectId2);

        // Assert
        expect(result1.id, equals(projectId1));
        expect(result2.id, equals(projectId2));
        
        // All other fields should be identical dummy data
        expect(result1.projectName, equals(result2.projectName));
        expect(result1.description, equals(result2.description));
        expect(result1.creatorUserId, equals(result2.creatorUserId));
        expect(result1.owningCompanyId, equals(result2.owningCompanyId));
        expect(result1.exportFolderLink, equals(result2.exportFolderLink));
        expect(result1.exportStorageProvider, equals(result2.exportStorageProvider));
        expect(result1.status, equals(result2.status));
        expect(result1.createdAt, equals(result2.createdAt));
        expect(result1.updatedAt, equals(result2.updatedAt));
      });
    });
  });
}
