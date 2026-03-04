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
