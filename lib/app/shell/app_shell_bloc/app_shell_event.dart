part of 'app_shell_bloc.dart';

/// Base class for all events handled by [AppShellBloc].
sealed class AppShellEvent extends Equatable {
  const AppShellEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered once when the shell first mounts, to load the initial tab module.
class AppShellInitialized extends AppShellEvent {
  const AppShellInitialized();
}

/// Event triggered when a user selects a tab in the app shell.
class AppShellTabSelected extends AppShellEvent {
  /// The tab that was selected.
  final ShellTab tab;

  const AppShellTabSelected(this.tab);

  @override
  List<Object> get props => [tab];
}

/// Internal event fired when [CurrentProjectNotifier] emits a new project ID.
class _AppShellCurrentProjectChanged extends AppShellEvent {
  final String? projectId;

  const _AppShellCurrentProjectChanged(this.projectId);

  @override
  List<Object?> get props => [projectId];
}
