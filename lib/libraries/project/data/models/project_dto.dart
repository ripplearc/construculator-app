import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for the [Project] entity.
///
/// This DTO represents the serialized form of a project as it appears
/// in the database or API responses. It is responsible for:
/// - Mapping raw JSON/database fields to strongly-typed Dart properties
/// - Applying fallback logic for timestamps and status values
/// - Converting storage provider strings into [StorageProvider] enums
/// - Converting to the domain [Project] entity via [toDomain].
class ProjectDto extends Equatable {
  static final _log = AppLogger().tag('ProjectDto');
  final String id;
  final String projectName;
  final String? description;
  final String creatorUserId;
  final String? owningCompanyId;
  final String? exportFolderLink;
  final String? exportStorageProvider;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectStatus status;

  const ProjectDto({
    required this.id,
    required this.projectName,
    this.description,
    required this.creatorUserId,
    this.owningCompanyId,
    this.exportFolderLink,
    this.exportStorageProvider,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    return ProjectDto(
      id: json[DatabaseConstants.idColumn] as String,
      projectName: json[DatabaseConstants.projectNameColumn] as String,
      description: json[DatabaseConstants.descriptionColumn] as String?,
      creatorUserId: json[DatabaseConstants.creatorUserIdColumn] as String,
      owningCompanyId:
          json[DatabaseConstants.owningCompanyIdColumn] as String?,
      exportFolderLink:
          json[DatabaseConstants.exportFolderLinkColumn] as String?,
      exportStorageProvider:
          json[DatabaseConstants.exportStorageProviderColumn] as String?,
      createdAt: _parseDateTime(json[DatabaseConstants.createdAtColumn]),
      updatedAt: _parseDateTime(json[DatabaseConstants.updatedAtColumn]),
      status: _parseProjectStatus(
        json[DatabaseConstants.statusColumn],
      ),
    );
  }

  Project toDomain() {
    return Project(
      id: id,
      projectName: projectName,
      description: description,
      creatorUserId: creatorUserId,
      owningCompanyId: owningCompanyId,
      exportFolderLink: exportFolderLink,
      exportStorageProvider: _parseStorageProvider(exportStorageProvider),
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (error, stackTrace) {
        _log.error(
          'Failed to parse DateTime from value "$value". Falling back to epoch.',
          error,
          stackTrace,
        );
      }
    } else {
      _log.warning(
        'Missing or null DateTime value for ProjectDto. Falling back to epoch.',
      );
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProjectStatus _parseProjectStatus(dynamic value) {
    switch (value?.toString()) {
      case 'archived':
        return ProjectStatus.archived;
      case 'active':
      default:
        return ProjectStatus.active;
    }
  }

  static StorageProvider? _parseStorageProvider(String? value) {
    switch (value) {
      case 'google_drive':
      case 'googleDrive':
        return StorageProvider.googleDrive;
      case 'one_drive':
      case 'oneDrive':
        return StorageProvider.oneDrive;
      case 'dropbox':
        return StorageProvider.dropbox;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
    id,
    projectName,
    description,
    creatorUserId,
    owningCompanyId,
    exportFolderLink,
    exportStorageProvider,
    createdAt,
    updatedAt,
    status,
  ];
}
