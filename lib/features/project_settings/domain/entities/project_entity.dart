import 'package:construculator/features/project_settings/domain/entities/enums.dart';

/// Represents a project in the system.
///
/// A project is a collection of data related to a construction project.
/// It includes the project name, description, creator user ID, owning company ID,
/// export folder link, export storage provider, created at, updated at, and status.
///
/// The project can be active or archived.
class Project {
  /// Unique identifier for the project.
  final String id;

  /// The name of the project.
  final String projectName;

  /// An optional description providing additional details about the project.
  final String? description;

  /// The user ID of the creator of the project.
  final String creatorUserId;

  /// The optional company ID that owns the project.
  final String? owningCompanyId;

  /// The optional link to the export folder for project data.
  final String? exportFolderLink;

  /// The optional storage provider used for exporting project data.
  final StorageProvider? exportStorageProvider;

  /// The date and time when the project was created.
  final DateTime createdAt;

  /// The date and time when the project was last updated.
  final DateTime updatedAt;

  /// The current status of the project (e.g., active, archived).
  final ProjectStatus status;

  Project({
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
}