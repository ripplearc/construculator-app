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
  /// The failure that caused the dashboard load to fail.
  final Failure failure;

  const DashboardError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Emitted after the user's display name is resolved, to show in the header.
class DashboardUserLoaded extends DashboardState {
  final String userDisplayName;

  const DashboardUserLoaded({required this.userDisplayName});

  @override
  List<Object?> get props => [userDisplayName];
}

/// One-shot state that signals navigation to the login screen.
class DashboardNavigateToLogin extends DashboardState {
  const DashboardNavigateToLogin();
}

/// One-shot state that signals navigation to the create-account screen.
class DashboardNavigateToCreateAccount extends DashboardState {
  final String? email;

  const DashboardNavigateToCreateAccount(this.email);

  @override
  List<Object?> get props => [email];
}
