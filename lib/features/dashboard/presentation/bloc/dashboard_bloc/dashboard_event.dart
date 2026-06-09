// coverage:ignore-file

part of 'dashboard_bloc.dart';

/// Base class for [DashboardBloc] events.
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers initial dashboard load — fetches the current project and wires
/// up the project-change subscription.
class DashboardLoadedEvent extends DashboardEvent {
  const DashboardLoadedEvent();
}

/// Triggers a full refresh of all dashboard data.
class DashboardRefreshedEvent extends DashboardEvent {
  const DashboardRefreshedEvent();
}

/// Requests a reload of recent calculations for the current project.
class RecentCalculationsLoadedEvent extends DashboardEvent {
  const RecentCalculationsLoadedEvent();
}

/// Requests a reload of recent estimations for the current project.
///
/// Note: recent estimations are reactively managed by [RecentEstimationsBloc].
/// This event is a no-op in [DashboardBloc].
class RecentEstimationsLoadedEvent extends DashboardEvent {
  const RecentEstimationsLoadedEvent();
}

/// Requests a reload of the user's favorites for the current project.
class FavoritesLoadedEvent extends DashboardEvent {
  const FavoritesLoadedEvent();
}

/// Internal event fired when [CurrentProjectNotifier] signals a project switch.
class _DashboardProjectChanged extends DashboardEvent {
  const _DashboardProjectChanged();
}
