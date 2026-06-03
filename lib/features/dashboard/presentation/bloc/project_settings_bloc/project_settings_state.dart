part of 'project_settings_bloc.dart';

/// Base state for [ProjectSettingsBloc].
abstract class ProjectSettingsState extends Equatable {
  const ProjectSettingsState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any watch has started.
class ProjectSettingsInitial extends ProjectSettingsState {
  const ProjectSettingsInitial();
}

/// Emitted while the project settings stream is being established.
class ProjectSettingsLoading extends ProjectSettingsState {
  const ProjectSettingsLoading();
}

/// Emitted when the stream delivers a successful project snapshot.
class ProjectSettingsLoaded extends ProjectSettingsState {
  /// The currently loaded project.
  final Project project;

  const ProjectSettingsLoaded(this.project);

  @override
  List<Object?> get props => [project];
}

/// Emitted when the user is actively editing the project.
class ProjectSettingsEditing extends ProjectSettingsState {
  /// The project with live edits applied.
  final Project project;

  /// A snapshot of the project before editing began, used to revert on failure.
  final Project originalProject;

  const ProjectSettingsEditing({
    required this.project,
    required this.originalProject,
  });

  /// Returns a copy with optional field overrides.
  ProjectSettingsEditing copyWith({Project? project, Project? originalProject}) {
    return ProjectSettingsEditing(
      project: project ?? this.project,
      originalProject: originalProject ?? this.originalProject,
    );
  }

  @override
  List<Object?> get props => [project, originalProject];
}

/// Emitted while an update request is in flight.
class ProjectSettingsSaving extends ProjectSettingsState {
  /// The project being saved.
  final Project project;

  const ProjectSettingsSaving(this.project);

  @override
  List<Object?> get props => [project];
}

/// Emitted while a delete request is in flight.
class ProjectSettingsDeleteInProgress extends ProjectSettingsState {
  const ProjectSettingsDeleteInProgress();
}

/// Emitted when any operation fails.
class ProjectSettingsError extends ProjectSettingsState {
  /// The failure describing what went wrong.
  final Failure failure;

  /// The last successfully loaded project, if available, for revert context.
  final Project? lastProject;

  const ProjectSettingsError({required this.failure, this.lastProject});

  @override
  List<Object?> get props => [failure, lastProject];
}
