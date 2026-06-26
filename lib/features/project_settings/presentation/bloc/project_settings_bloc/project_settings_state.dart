// coverage:ignore-file
part of 'project_settings_bloc.dart';

/// Base state for [ProjectSettingsBloc].
abstract class ProjectSettingsState extends Equatable {
  const ProjectSettingsState();

  @override
  List<Object?> get props => [];
}

class ProjectSettingsInitial extends ProjectSettingsState {
  const ProjectSettingsInitial();
}

class ProjectSettingsLoading extends ProjectSettingsState {
  const ProjectSettingsLoading();
}

class ProjectSettingsLoaded extends ProjectSettingsState {
  final Project project;

  const ProjectSettingsLoaded(this.project);

  @override
  List<Object?> get props => [project];
}

class ProjectSettingsEditing extends ProjectSettingsState {
  final Project project;
  final Project originalProject;

  const ProjectSettingsEditing({
    required this.project,
    required this.originalProject,
  });

  ProjectSettingsEditing copyWith({Project? project, Project? originalProject}) {
    return ProjectSettingsEditing(
      project: project ?? this.project,
      originalProject: originalProject ?? this.originalProject,
    );
  }

  @override
  List<Object?> get props => [project, originalProject];
}

class ProjectSettingsSaving extends ProjectSettingsState {
  final Project project;

  const ProjectSettingsSaving(this.project);

  @override
  List<Object?> get props => [project];
}

class ProjectSettingsDeleteInProgress extends ProjectSettingsState {
  const ProjectSettingsDeleteInProgress();
}

class ProjectSettingsCreating extends ProjectSettingsState {
  const ProjectSettingsCreating();
}

class ProjectSettingsCreated extends ProjectSettingsState {
  final Project project;

  const ProjectSettingsCreated(this.project);

  @override
  List<Object?> get props => [project];
}

class ProjectSettingsEdited extends ProjectSettingsState {
  final Project project;

  const ProjectSettingsEdited(this.project);

  @override
  List<Object?> get props => [project];
}

class ProjectSettingsError extends ProjectSettingsState {
  final Failure failure;
  final Project? lastProject;

  const ProjectSettingsError({required this.failure, this.lastProject});

  @override
  List<Object?> get props => [failure, lastProject];
}
