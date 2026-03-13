import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

class ProjectDto extends Equatable {
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
      projectName: json['project_name'] as String,
      description: json['description'] as String?,
      creatorUserId: json[DatabaseConstants.creatorUserIdColumn] as String,
      owningCompanyId: json['owning_company_id'] as String?,
      exportFolderLink: json['export_folder_link'] as String?,
      exportStorageProvider: json['export_storage_provider'] as String?,
      createdAt: _parseDateTime(json[DatabaseConstants.createdAtColumn]),
      updatedAt: _parseDateTime(json[DatabaseConstants.updatedAtColumn]),
      status: _parseProjectStatus(
        json[DatabaseConstants.statusColumn] ?? json['project_status'],
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
      return DateTime.parse(value);
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
