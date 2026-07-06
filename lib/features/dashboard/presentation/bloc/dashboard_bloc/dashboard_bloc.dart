import 'dart:async';

import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Manages auth state, user display name, and current-project loading.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ProjectRepository _projectRepository;
  final CurrentProjectNotifier _currentProjectNotifier;
  final AuthNotifier _authNotifier;
  final AuthManager _authManager;
  StreamSubscription<String?>? _projectSubscription;
  StreamSubscription<User?>? _profileSubscription;
  String _userDisplayName = '...';

  DashboardBloc({
    required ProjectRepository projectRepository,
    required CurrentProjectNotifier currentProjectNotifier,
    required AuthNotifier authNotifier,
    required AuthManager authManager,
  })  : _projectRepository = projectRepository,
        _currentProjectNotifier = currentProjectNotifier,
        _authNotifier = authNotifier,
        _authManager = authManager,
        super(const DashboardInitial()) {
    on<DashboardStarted>(_onDashboardStarted);
    on<DashboardLoadedEvent>(_onDashboardLoaded);
    on<DashboardRefreshedEvent>(_onDashboardRefreshed);
    on<FavoritesLoadedEvent>(_onFavoritesLoaded);
    on<DashboardLogoutRequested>(_onDashboardLogoutRequested);
    on<_DashboardProjectChanged>(_onProjectChanged);
    on<_DashboardUserProfileChanged>(_onUserProfileChanged);
  }

  Future<void> _onDashboardStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    final cred = _authManager.getCurrentCredentials();
    if (cred.data?.id == null) {
      emit(const DashboardNavigateToLogin());
      return;
    }

    final credData = cred.data;
    final result = await _authManager.getUserProfile(credData?.id ?? '');
    final profile = result.data;
    if (result.isSuccess && profile != null) {
      _userDisplayName = '${profile.firstName} ${profile.lastName}!';
      emit(DashboardUserLoaded(userDisplayName: _userDisplayName));
    } else {
      emit(DashboardNavigateToCreateAccount(credData?.email));
      return;
    }

    _profileSubscription ??= _authNotifier.onUserProfileChanged.listen((user) {
      add(_DashboardUserProfileChanged(user));
    });
  }

  void _onUserProfileChanged(
    _DashboardUserProfileChanged event,
    Emitter<DashboardState> emit,
  ) {
    final user = event.user;
    if (user == null) {
      final cred = _authManager.getCurrentCredentials();
      emit(DashboardNavigateToCreateAccount(cred.data?.email));
    } else {
      _userDisplayName = '${user.firstName} ${user.lastName}!';
      emit(DashboardUserLoaded(userDisplayName: _userDisplayName));
    }
  }

  Future<void> _onDashboardLogoutRequested(
    DashboardLogoutRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _authManager.logout();
    emit(const DashboardNavigateToLogin());
  }

  Future<void> _onDashboardLoaded(
    DashboardLoadedEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadDashboard(emit);
  }

  Future<void> _onDashboardRefreshed(
    DashboardRefreshedEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadDashboard(emit);
  }

  Future<void> _onFavoritesLoaded(
    FavoritesLoadedEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // TODO: [CA-247] Call GetProjectFavoritesUseCase once FavoritesRepository
    // is implemented. https://ripplearc.youtrack.cloud/issue/CA-247
  }

  void _onProjectChanged(
    _DashboardProjectChanged event,
    Emitter<DashboardState> emit,
  ) {
    add(const DashboardLoadedEvent());
  }

  Future<void> _loadDashboard(Emitter<DashboardState> emit) async {
    emit(const DashboardLoading());

    _projectSubscription ??= _currentProjectNotifier.onCurrentProjectChanged
        .listen((_) => add(const _DashboardProjectChanged()));

    final projectId = _currentProjectNotifier.currentProjectId;
    if (projectId == null || projectId.isEmpty) {
      emit(DashboardError(UnexpectedFailure()));
      return;
    }

    try {
      final project = await _projectRepository.getProject(projectId);
      // TODO: [CA-247] Fetch and include ProjectFavorites in DashboardLoaded.
      emit(DashboardLoaded(currentProject: project));
    } catch (_) {
      emit(DashboardError(UnexpectedFailure()));
    }
  }

  @override
  Future<void> close() {
    _projectSubscription?.cancel();
    _profileSubscription?.cancel();
    return super.close();
  }
}
