// coverage:ignore-file
part of 'get_project_bloc.dart';

/// Base class for all Get Project events.
sealed class GetProjectEvent extends Equatable {
  const GetProjectEvent();

  @override
  List<Object> get props => [];
}

/// Starts observing [CurrentProjectNotifier] and loads the current project.
///
/// Dispatched once by the presentation layer when the header app bar mounts.
/// Subsequent project switches are handled internally via [_GetProjectCurrentProjectChanged].
class GetProjectWatchStarted extends GetProjectEvent {
  const GetProjectWatchStarted();
}

/// Requests loading a project by its id (initial fetch).
///
/// This event triggers the initial load of project data.
/// A duplicate guard prevents multiple consecutive load requests from being processed.
class GetProjectByIdLoadRequested extends GetProjectEvent {
  const GetProjectByIdLoadRequested(this.projectId);

  final String projectId;

  @override
  List<Object> get props => [projectId];
}

/// Requests reloading a project by its id (refresh flow).
///
/// This event triggers a refresh of the currently loaded project data.
/// Unlike [GetProjectByIdLoadRequested], this event does not check the current
/// state before firing, allowing multiple consecutive refresh requests to be processed.
class GetProjectByIdRefreshRequested extends GetProjectEvent {
  final String projectId;

  const GetProjectByIdRefreshRequested(this.projectId);

  @override
  List<Object> get props => [projectId];
}

/// Internal event emitted when [CurrentProjectNotifier] signals a project switch.
class _GetProjectCurrentProjectChanged extends GetProjectEvent {
  const _GetProjectCurrentProjectChanged(this.projectId);

  final String? projectId;

  @override
  List<Object> get props {
    final id = projectId;
    return id != null ? [id] : [];
  }
}
