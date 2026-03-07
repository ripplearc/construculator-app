part of 'project_dropdown_bloc.dart';

/// Base class for project dropdown events.
abstract class ProjectDropdownEvent extends Equatable {
  const ProjectDropdownEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers initial project list load.
class ProjectDropdownStarted extends ProjectDropdownEvent {
  const ProjectDropdownStarted();
}

/// Selects a project from the loaded project list.
class ProjectDropdownSelected extends ProjectDropdownEvent {
  final String projectId;

  const ProjectDropdownSelected(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// Triggers an update event when the project list is updated.
class _ProjectDropdownProjectsUpdated extends ProjectDropdownEvent {
  final List<Project> projects;

  const _ProjectDropdownProjectsUpdated(this.projects);

  @override
  List<Object?> get props => [projects];
}
/// Triggers a failure event when project list loading fails.
class _ProjectDropdownProjectsLoadFailed extends ProjectDropdownEvent {
  final String message;

  const _ProjectDropdownProjectsLoadFailed(this.message);

  @override
  List<Object?> get props => [message];
}
