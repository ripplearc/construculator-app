// coverage:ignore-file

part of 'dashboard_bloc.dart';

/// Base class for [DashboardBloc] events.
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
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

/// Internal event fired when [CurrentProjectNotifier] signals a project switch.
class _DashboardProjectChanged extends DashboardEvent {
  const _DashboardProjectChanged();
}
