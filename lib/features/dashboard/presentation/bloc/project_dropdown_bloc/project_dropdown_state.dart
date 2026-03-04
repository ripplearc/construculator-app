part of 'project_dropdown_bloc.dart';

/// Base class for project dropdown states.
abstract class ProjectDropdownState extends Equatable {
  const ProjectDropdownState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any loading starts.
class ProjectDropdownInitial extends ProjectDropdownState {
  const ProjectDropdownInitial();
}

/// State emitted while loading projects.
class ProjectDropdownLoadInProgress extends ProjectDropdownState {
  const ProjectDropdownLoadInProgress();
}

/// State emitted when projects are loaded successfully.
class ProjectDropdownLoadSuccess extends ProjectDropdownState {
  final UnmodifiableListView<Project> projects;
  final Project? selectedProject;

  ProjectDropdownLoadSuccess({
    required List<Project> projects,
    required this.selectedProject,
  }) : projects = UnmodifiableListView<Project>(List<Project>.from(projects));

  ProjectDropdownLoadSuccess copyWith({Project? selectedProject}) {
    return ProjectDropdownLoadSuccess(
      projects: projects.toList(),
      selectedProject: selectedProject ?? this.selectedProject,
    );
  }

  @override
  List<Object?> get props => [projects, selectedProject];
}

/// State emitted when loading projects fails.
class ProjectDropdownLoadFailure extends ProjectDropdownState {
  final String message;

  const ProjectDropdownLoadFailure(this.message);

  @override
  List<Object?> get props => [message];
}
