part of 'app_shell_bloc.dart';

/// Base class for all events handled by [AppShellBloc].
sealed class AppShellEvent extends Equatable {
  const AppShellEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered when a user selects a tab in the app shell.
class AppShellTabSelected extends AppShellEvent {
  /// The index of the selected tab.
  final int index;

  const AppShellTabSelected(this.index);

  @override
  List<Object> get props => [index];
}
