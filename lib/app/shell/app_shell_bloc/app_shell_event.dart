part of 'app_shell_bloc.dart';

/// Base class for all events handled by the [AppShellBloc].
sealed class AppShellEvent extends Equatable {
  const AppShellEvent();

  @override
  List<Object> get props => [];
}

/// Event fired when a user selects a tab in the app's bottom navigation bar.
class AppShellTabSelected extends AppShellEvent {
  /// The index of the newly selected tab.
  final int index;

  const AppShellTabSelected(this.index);

  @override
  List<Object> get props => [index];
}
