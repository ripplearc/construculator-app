// coverage:ignore-file
part of 'project_settings_bloc.dart';

/// Base event for [ProjectSettingsBloc].
abstract class ProjectSettingsEvent extends Equatable {
  const ProjectSettingsEvent();

  @override
  List<Object?> get props => [];
}

class ProjectSettingsLoadRequested extends ProjectSettingsEvent {
  final String projectId;

  const ProjectSettingsLoadRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class ProjectSettingsEditingStarted extends ProjectSettingsEvent {
  final Project project;

  const ProjectSettingsEditingStarted(this.project);

  @override
  List<Object?> get props => [project];
}

class ProjectSettingsUpdateSubmitted extends ProjectSettingsEvent {
  final Project project;

  const ProjectSettingsUpdateSubmitted(this.project);

  @override
  List<Object?> get props => [project];
}

class ProjectSettingsDeleteRequested extends ProjectSettingsEvent {
  final String projectId;

  const ProjectSettingsDeleteRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class ProjectSettingsCreationRequested extends ProjectSettingsEvent {
  final String name;
  final String? description;
  final String? creatorUserId;
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
