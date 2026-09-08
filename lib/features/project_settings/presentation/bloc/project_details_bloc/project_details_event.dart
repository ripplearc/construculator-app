// coverage:ignore-file
part of 'project_details_bloc.dart';

/// Base class for all project details events.
sealed class ProjectDetailsEvent extends Equatable {
  const ProjectDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Requests the initial load of the project with the given [projectId].
///
/// A duplicate guard skips the fetch when the same project is already loaded.
class ProjectDetailsStarted extends ProjectDetailsEvent {
  const ProjectDetailsStarted(this.projectId);

  /// Identifier of the project to load.
  final String projectId;

  @override
  List<Object?> get props => [projectId];
}

/// Requests a reload of the project with the given [projectId].
///
/// Unlike [ProjectDetailsStarted], this always refetches regardless of the
/// current state.
class ProjectDetailsRefreshed extends ProjectDetailsEvent {
  const ProjectDetailsRefreshed(this.projectId);

  /// Identifier of the project to refetch.
  final String projectId;

  @override
  List<Object?> get props => [projectId];
}
