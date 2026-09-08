// coverage:ignore-file
part of 'project_settings_bloc.dart';

/// Base event for [ProjectSettingsBloc].
abstract class ProjectSettingsEvent extends Equatable {
  const ProjectSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Requests a one-time load of the project settings for [projectId].
class ProjectSettingsLoadRequested extends ProjectSettingsEvent {
  /// The identifier of the project to load.
  final String projectId;

  const ProjectSettingsLoadRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// Signals that the user has begun editing [project].
class ProjectSettingsEditingStarted extends ProjectSettingsEvent {
  /// The project to enter edit mode for.
  final Project project;

  const ProjectSettingsEditingStarted(this.project);

  @override
  List<Object?> get props => [project];
}

/// Submits updated [project] fields for persistence.
class ProjectSettingsUpdateSubmitted extends ProjectSettingsEvent {
  /// The project with updated fields to persist.
  final Project project;

  const ProjectSettingsUpdateSubmitted(this.project);

  @override
  List<Object?> get props => [project];
}

/// Requests permanent deletion of the project identified by [projectId].
class ProjectSettingsDeleteRequested extends ProjectSettingsEvent {
  /// The identifier of the project to delete.
  final String projectId;

  const ProjectSettingsDeleteRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// Cancels the current edit, restoring the original project state.
class ProjectSettingsEditingCancelled extends ProjectSettingsEvent {
  const ProjectSettingsEditingCancelled();
}

/// Requests creation of a new project with the given fields.
class ProjectSettingsCreationRequested extends ProjectSettingsEvent {
  /// The display name for the new project.
  final String name;

  /// An optional description for the new project.
  final String? description;

  /// The authenticated user ID of the creator. Null triggers an error state.
  final String? creatorUserId;

  /// The preferred storage provider for exports.
  final StorageProvider? exportStorageProvider;

  const ProjectSettingsCreationRequested({
    required this.name,
    this.creatorUserId,
    this.description,
    this.exportStorageProvider,
  });

  @override
  List<Object?> get props => [name, description, creatorUserId, exportStorageProvider];
}
