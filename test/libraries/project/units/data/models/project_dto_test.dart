import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectDto.fromJson', () {
    test('parses all fields when populated', () {
      final createdAt = DateTime(2025, 1, 1, 10, 30);
      final updatedAt = DateTime(2025, 1, 2, 11, 45);

      final json = <String, dynamic>{
        DatabaseConstants.idColumn: 'project-123',
        DatabaseConstants.projectNameColumn: 'My Project',
        DatabaseConstants.descriptionColumn: 'A test project',
        DatabaseConstants.creatorUserIdColumn: 'creator-1',
        DatabaseConstants.owningCompanyIdColumn: 'company-1',
        DatabaseConstants.exportFolderLinkColumn: 'https://example.com/folder',
        DatabaseConstants.exportStorageProviderColumn: 'google_drive',
        DatabaseConstants.createdAtColumn: createdAt.toIso8601String(),
        DatabaseConstants.updatedAtColumn: updatedAt.toIso8601String(),
        DatabaseConstants.statusColumn: 'archived',
      };

      final dto = ProjectDto.fromJson(json);

      expect(dto.id, 'project-123');
      expect(dto.projectName, 'My Project');
      expect(dto.description, 'A test project');
      expect(dto.creatorUserId, 'creator-1');
      expect(dto.owningCompanyId, 'company-1');
      expect(dto.exportFolderLink, 'https://example.com/folder');
      expect(dto.exportStorageProvider, 'google_drive');
      expect(dto.createdAt, createdAt);
      expect(dto.updatedAt, updatedAt);
      expect(dto.status, ProjectStatus.archived);
    });

    test('handles nullable fields when absent', () {
      final createdAt = DateTime(2025, 1, 1, 10, 30);
      final updatedAt = DateTime(2025, 1, 2, 11, 45);

      final json = <String, dynamic>{
        DatabaseConstants.idColumn: 'project-123',
        DatabaseConstants.projectNameColumn: 'My Project',
        DatabaseConstants.creatorUserIdColumn: 'creator-1',
        DatabaseConstants.createdAtColumn: createdAt.toIso8601String(),
        DatabaseConstants.updatedAtColumn: updatedAt.toIso8601String(),
        DatabaseConstants.statusColumn: 'active',
      };

      final dto = ProjectDto.fromJson(json);

      expect(dto.description, isNull);
      expect(dto.owningCompanyId, isNull);
      expect(dto.exportFolderLink, isNull);
      expect(dto.exportStorageProvider, isNull);
      expect(dto.status, ProjectStatus.active);
    });

    test('falls back for invalid DateTime string', () {
      final json = <String, dynamic>{
        DatabaseConstants.idColumn: 'project-123',
        DatabaseConstants.projectNameColumn: 'My Project',
        DatabaseConstants.creatorUserIdColumn: 'creator-1',
        DatabaseConstants.createdAtColumn: 'not-a-date',
        DatabaseConstants.updatedAtColumn: 'also-not-a-date',
        DatabaseConstants.statusColumn: 'active',
      };

      final dto = ProjectDto.fromJson(json);

      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      expect(dto.createdAt, epoch);
      expect(dto.updatedAt, epoch);
    });

    test('falls back for empty DateTime strings', () {
      final json = <String, dynamic>{
        DatabaseConstants.idColumn: 'project-123',
        DatabaseConstants.projectNameColumn: 'My Project',
        DatabaseConstants.creatorUserIdColumn: 'creator-1',
        DatabaseConstants.createdAtColumn: '',
        DatabaseConstants.updatedAtColumn: '',
        DatabaseConstants.statusColumn: 'active',
      };

      final dto = ProjectDto.fromJson(json);

      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      expect(dto.createdAt, epoch);
      expect(dto.updatedAt, epoch);
    });

    test('falls back for null DateTime values', () {
      final json = <String, dynamic>{
        DatabaseConstants.idColumn: 'project-123',
        DatabaseConstants.projectNameColumn: 'My Project',
        DatabaseConstants.creatorUserIdColumn: 'creator-1',
        DatabaseConstants.createdAtColumn: null,
        DatabaseConstants.updatedAtColumn: null,
        DatabaseConstants.statusColumn: 'active',
      };

      final dto = ProjectDto.fromJson(json);

      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      expect(dto.createdAt, epoch);
      expect(dto.updatedAt, epoch);
    });

    test('parses DateTime objects directly', () {
      final createdAt = DateTime(2025, 1, 1, 10, 30);
      final updatedAt = DateTime(2025, 1, 2, 11, 45);

      final json = <String, dynamic>{
        DatabaseConstants.idColumn: 'project-123',
        DatabaseConstants.projectNameColumn: 'My Project',
        DatabaseConstants.creatorUserIdColumn: 'creator-1',
        DatabaseConstants.createdAtColumn: createdAt,
        DatabaseConstants.updatedAtColumn: updatedAt,
        DatabaseConstants.statusColumn: 'active',
      };

      final dto = ProjectDto.fromJson(json);

      expect(dto.createdAt, createdAt);
      expect(dto.updatedAt, updatedAt);
    });

    test('parses project status correctly for known and unknown values', () {
      final baseJson = <String, dynamic>{
        DatabaseConstants.idColumn: 'project-123',
        DatabaseConstants.projectNameColumn: 'My Project',
        DatabaseConstants.creatorUserIdColumn: 'creator-1',
        DatabaseConstants.createdAtColumn:
            DateTime(2025, 1, 1, 10, 30).toIso8601String(),
        DatabaseConstants.updatedAtColumn:
            DateTime(2025, 1, 2, 11, 45).toIso8601String(),
      };

      final archived = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.statusColumn: 'archived',
      });
      final active = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.statusColumn: 'active',
      });
      final unknown = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.statusColumn: 'something-else',
      });
      final nullStatus = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.statusColumn: null,
      });

      expect(archived.status, ProjectStatus.archived);
      expect(active.status, ProjectStatus.active);
      expect(unknown.status, ProjectStatus.active);
      expect(nullStatus.status, ProjectStatus.active);
    });

    test('parses export storage provider correctly', () {
      final baseJson = <String, dynamic>{
        DatabaseConstants.idColumn: 'project-123',
        DatabaseConstants.projectNameColumn: 'My Project',
        DatabaseConstants.creatorUserIdColumn: 'creator-1',
        DatabaseConstants.createdAtColumn:
            DateTime(2025, 1, 1, 10, 30).toIso8601String(),
        DatabaseConstants.updatedAtColumn:
            DateTime(2025, 1, 2, 11, 45).toIso8601String(),
        DatabaseConstants.statusColumn: 'active',
      };

      final googleDriveSnake = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.exportStorageProviderColumn: 'google_drive',
      }).toDomain();
      final googleDriveCamel = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.exportStorageProviderColumn: 'googleDrive',
      }).toDomain();
      final oneDriveSnake = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.exportStorageProviderColumn: 'one_drive',
      }).toDomain();
      final oneDriveCamel = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.exportStorageProviderColumn: 'oneDrive',
      }).toDomain();
      final dropbox = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.exportStorageProviderColumn: 'dropbox',
      }).toDomain();
      final unknown = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.exportStorageProviderColumn: 'some-other-provider',
      }).toDomain();
      final nullProvider = ProjectDto.fromJson({
        ...baseJson,
        DatabaseConstants.exportStorageProviderColumn: null,
      }).toDomain();

      expect(googleDriveSnake.exportStorageProvider, StorageProvider.googleDrive);
      expect(googleDriveCamel.exportStorageProvider, StorageProvider.googleDrive);
      expect(oneDriveSnake.exportStorageProvider, StorageProvider.oneDrive);
      expect(oneDriveCamel.exportStorageProvider, StorageProvider.oneDrive);
      expect(dropbox.exportStorageProvider, StorageProvider.dropbox);
      expect(unknown.exportStorageProvider, isNull);
      expect(nullProvider.exportStorageProvider, isNull);
    });
  });

  group('ProjectDto.toDomain', () {
    test('maps all fields correctly to Project', () {
      final dto = ProjectDto(
        id: 'project-123',
        projectName: 'My Project',
        description: 'A test project',
        creatorUserId: 'creator-1',
        owningCompanyId: 'company-1',
        exportFolderLink: 'https://example.com/folder',
        exportStorageProvider: 'google_drive',
        createdAt: DateTime(2025, 1, 1, 10, 30),
        updatedAt: DateTime(2025, 1, 2, 11, 45),
        status: ProjectStatus.active,
      );

      final project = dto.toDomain();

      expect(project, isA<Project>());
      expect(project.id, dto.id);
      expect(project.projectName, dto.projectName);
      expect(project.description, dto.description);
      expect(project.creatorUserId, dto.creatorUserId);
      expect(project.owningCompanyId, dto.owningCompanyId);
      expect(project.exportFolderLink, dto.exportFolderLink);
      expect(project.exportStorageProvider, StorageProvider.googleDrive);
      expect(project.createdAt, dto.createdAt);
      expect(project.updatedAt, dto.updatedAt);
      expect(project.status, dto.status);
    });
  });
}

