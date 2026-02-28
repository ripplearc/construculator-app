part of 'app_shell_bloc.dart';

sealed class AppShellEvent extends Equatable {
  const AppShellEvent();

  @override
  List<Object> get props => [];
}

class AppShellTabSelected extends AppShellEvent {
  final int index;

  const AppShellTabSelected(this.index);

  @override
  List<Object> get props => [index];
}
