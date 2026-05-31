part of 'project_settings_bloc.dart';

/// Base state for [ProjectSettingsBloc].
abstract class ProjectSettingsState extends Equatable {
  /// Defines a constant constructor for project settings state.
  const ProjectSettingsState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any watch has started.
class ProjectSettingsInitial extends ProjectSettingsState {
  /// Defines a constant constructor for the initial state.
  const ProjectSettingsInitial();
}

/// Emitted while the project settings stream is being established.
class ProjectSettingsLoading extends ProjectSettingsState {
  /// Defines a constant constructor for the loading state.
  const ProjectSettingsLoading();
}

/// Emitted when the stream delivers a successful project snapshot.
class ProjectSettingsLoaded extends ProjectSettingsState {
  /// The currently loaded project.
  final Project project;

  /// Defines a constructor taking [project].
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

  /// Defines a constructor taking [project] and [originalProject].
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

  /// Defines a constructor taking [project].
  const ProjectSettingsSaving(this.project);

  @override
  List<Object?> get props => [project];
}

/// Emitted while a delete request is in flight.
class ProjectSettingsDeleteInProgress extends ProjectSettingsState {
  /// Defines a constant constructor for the delete-in-progress state.
  const ProjectSettingsDeleteInProgress();
}

/// Emitted when any operation fails.
class ProjectSettingsError extends ProjectSettingsState {
  /// The failure describing what went wrong.
  final Failure failure;

  /// The last successfully loaded project, if available, for revert context.
  final Project? lastProject;

  /// Defines a constructor taking [failure] and an optional [lastProject].
  const ProjectSettingsError({required this.failure, this.lastProject});

  @override
  List<Object?> get props => [failure, lastProject];
}
