import 'dart:async';

import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Manages the overall dashboard loading state.
///
/// Owns the current-project fetch and wires up project-switch reactivity via
/// [CurrentProjectNotifier]. Dedicated blocs own sub-sections:
///   - [RecentEstimationsBloc]: recent estimations (streaming)
///   - TODO: future RecentCalculationsBloc for calculations
///   - TODO: [CA-247] GetProjectFavoritesUseCase for favorites
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ProjectRepository _projectRepository;
  final CurrentProjectNotifier _currentProjectNotifier;
  StreamSubscription<String?>? _projectSubscription;

  DashboardBloc({
    required ProjectRepository projectRepository,
    required CurrentProjectNotifier currentProjectNotifier,
  })  : _projectRepository = projectRepository,
        _currentProjectNotifier = currentProjectNotifier,
        super(const DashboardInitial()) {
    on<DashboardLoadedEvent>(_onDashboardLoaded);
    on<DashboardRefreshedEvent>(_onDashboardRefreshed);
    on<RecentCalculationsLoadedEvent>(_onRecentCalculationsLoaded);
    on<RecentEstimationsLoadedEvent>(_onRecentEstimationsLoaded);
    on<FavoritesLoadedEvent>(_onFavoritesLoaded);
    on<_DashboardProjectChanged>(_onProjectChanged);
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

  Future<void> _onRecentCalculationsLoaded(
    RecentCalculationsLoadedEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // TODO: future ticket — wire GetRecentCalculationsUseCase here once
    // the Calculations library module and its use case are implemented.
  }

  Future<void> _onRecentEstimationsLoaded(
    RecentEstimationsLoadedEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // Recent estimations are handled reactively by RecentEstimationsBloc.
    // No action needed in DashboardBloc.
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
      emit(const DashboardError('No active project selected.'));
      return;
    }

    try {
      final project = await _projectRepository.getProject(projectId);
      // TODO: [CA-247] Fetch and include ProjectFavorites in DashboardLoaded.
      emit(DashboardLoaded(currentProject: project));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _projectSubscription?.cancel();
    return super.close();
  }
}
