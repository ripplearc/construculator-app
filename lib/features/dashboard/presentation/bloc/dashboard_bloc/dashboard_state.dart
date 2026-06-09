// coverage:ignore-file

part of 'dashboard_bloc.dart';

/// Base class for [DashboardBloc] states.
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// State before any load event has been dispatched.
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Emitted while the dashboard is fetching data.
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Emitted when the dashboard has successfully loaded all required data.
class DashboardLoaded extends DashboardState {
  /// The currently selected project.
  final Project currentProject;

  // TODO: [CA-247] Add ProjectFavorites favorites once FavoritesRepository
  // and GetProjectFavoritesUseCase are implemented.
  // https://ripplearc.youtrack.cloud/issue/CA-247

  const DashboardLoaded({required this.currentProject});

  @override
  List<Object?> get props => [currentProject];
}

/// Emitted when any dashboard load operation fails.
class DashboardError extends DashboardState {
  /// Human-readable description of the failure.
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
