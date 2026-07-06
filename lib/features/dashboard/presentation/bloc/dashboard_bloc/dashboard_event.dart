// coverage:ignore-file

part of 'dashboard_bloc.dart';

/// Base class for [DashboardBloc] events.
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the auth check and subscribes to profile changes.
class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

/// Triggers initial dashboard load.
class DashboardLoadedEvent extends DashboardEvent {
  const DashboardLoadedEvent();
}

/// Triggers a full refresh of all dashboard data.
class DashboardRefreshedEvent extends DashboardEvent {
  const DashboardRefreshedEvent();
}

/// Requests a reload of the user's favorites for the current project.
class FavoritesLoadedEvent extends DashboardEvent {
  const FavoritesLoadedEvent();
}

/// Requests a logout and navigates to the login screen.
class DashboardLogoutRequested extends DashboardEvent {
  const DashboardLogoutRequested();
}

/// Internal event fired when [CurrentProjectNotifier] signals a project switch.
class _DashboardProjectChanged extends DashboardEvent {
  const _DashboardProjectChanged();
}

/// Internal event fired when the auth notifier emits a user profile change.
class _DashboardUserProfileChanged extends DashboardEvent {
  final User? user;
  const _DashboardUserProfileChanged(this.user);

  @override
  List<Object?> get props => [user];
}
