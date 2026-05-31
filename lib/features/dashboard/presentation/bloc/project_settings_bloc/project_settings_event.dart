part of 'project_settings_bloc.dart';

/// Base event for [ProjectSettingsBloc].
abstract class ProjectSettingsEvent extends Equatable {
  /// Defines a constant constructor for project settings event.
  const ProjectSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Starts (or restarts) the project settings stream for [projectId].
class ProjectSettingsWatchStarted extends ProjectSettingsEvent {
  /// The identifier of the project to watch.
  final String projectId;

  /// Defines a constructor to start watching project settings.
  const ProjectSettingsWatchStarted(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// Signals that the user has begun editing [project].
class ProjectSettingsEditingStarted extends ProjectSettingsEvent {
  /// The project to enter edit mode for.
  final Project project;

  /// Defines a constructor to start editing a project.
  const ProjectSettingsEditingStarted(this.project);

  @override
  List<Object?> get props => [project];
}

/// Submits updated [project] fields for persistence.
class ProjectSettingsUpdateSubmitted extends ProjectSettingsEvent {
  /// The project with updated fields to persist.
  final Project project;

  /// Defines a constructor to submit project updates.
  const ProjectSettingsUpdateSubmitted(this.project);

  @override
  List<Object?> get props => [project];
}

/// Requests permanent deletion of the project identified by [projectId].
class ProjectSettingsDeleteRequested extends ProjectSettingsEvent {
  /// The identifier of the project to delete.
  final String projectId;

  /// Defines a constructor to request project deletion.
  const ProjectSettingsDeleteRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class _ProjectSettingsStreamUpdated extends ProjectSettingsEvent {
  final Either<Failure, Project> result;

  const _ProjectSettingsStreamUpdated(this.result);

  @override
  List<Object?> get props => [result];
}
