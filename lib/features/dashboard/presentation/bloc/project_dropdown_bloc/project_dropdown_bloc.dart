import 'dart:async';
import 'dart:collection';

import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'project_dropdown_event.dart';
part 'project_dropdown_state.dart';

/// BLoC that manages the project dropdown list and the currently selected project.
///
/// When a project is selected via [ProjectDropdownSelected], the BLoC updates
/// [CurrentProjectNotifier] so that project-dependent consumers (e.g.
/// [RecentEstimationsBloc]) refresh automatically.
class ProjectDropdownBloc
    extends Bloc<ProjectDropdownEvent, ProjectDropdownState> {
  final ProjectRepository _projectRepository;
  final AuthManager _authManager;
  final CurrentProjectNotifier _currentProjectNotifier;
  StreamSubscription<List<Project>>? _projectsSubscription;

  /// Creates a [ProjectDropdownBloc].
  ///
  /// [projectRepository] provides the project list stream.
  /// [authManager] supplies the authenticated user identity.
  /// [currentProjectNotifier] is updated whenever the selected project changes.
  ProjectDropdownBloc({
    required ProjectRepository projectRepository,
    required AuthManager authManager,
    required CurrentProjectNotifier currentProjectNotifier,
  }) : _projectRepository = projectRepository,
       _authManager = authManager,
       _currentProjectNotifier = currentProjectNotifier,
       super(const ProjectDropdownInitial()) {
    on<ProjectDropdownStarted>(_onStarted);
    on<ProjectDropdownSelected>(_onSelected);
    on<ProjectDropdownSearchChanged>(_onSearchChanged);
    on<_ProjectDropdownProjectsUpdated>(_onProjectsUpdated);
    on<_ProjectDropdownProjectsLoadFailed>(_onProjectsLoadFailed);
  }

  @override
  Future<void> close() {
    _projectsSubscription?.cancel();
    // Do not close _currentProjectNotifier — it is DI-owned.
    return super.close();
  }

  Future<void> _onStarted(
    ProjectDropdownStarted event,
    Emitter<ProjectDropdownState> emit,
  ) async {
    emit(const ProjectDropdownLoadInProgress());

    final userId = _authManager.getCurrentCredentials().data?.id ?? '';
    if (userId.isEmpty) {
      emit(
        ProjectDropdownLoadSuccess(projects: const [], selectedProject: null),
      );
      return;
    }

    await _projectsSubscription?.cancel();
    _projectsSubscription = _projectRepository
        .watchProjects(userId)
        .listen(
          (projects) => add(_ProjectDropdownProjectsUpdated(projects)),
          onError: (Object error, StackTrace stackTrace) {
            add(_ProjectDropdownProjectsLoadFailed(
              error is Failure ? error : UnexpectedFailure(),
            ));
          },
        );
  }

  void _onProjectsUpdated(
    _ProjectDropdownProjectsUpdated event,
    Emitter<ProjectDropdownState> emit,
  ) {
    final currentState = state;
    final searchQuery = switch (currentState) {
      ProjectDropdownLoadSuccess s => s.searchQuery,
      _ => '',
    };

    if (event.projects.isEmpty) {
      emit(
        ProjectDropdownLoadSuccess(
          projects: const [],
          selectedProject: null,
          searchQuery: searchQuery,
        ),
      );
      return;
    }

    Project selectedProject = event.projects.first;

    if (currentState is ProjectDropdownLoadSuccess) {
      final currentSelection = currentState.selectedProject;
      if (currentSelection != null) {
        for (final project in event.projects) {
          if (project.id == currentSelection.id) {
            selectedProject = project;
            break;
          }
        }
      }
    }

    emit(
      ProjectDropdownLoadSuccess(
        projects: event.projects,
        selectedProject: selectedProject,
        searchQuery: searchQuery,
      ),
    );

    // Notifier is updated after emit — consistent with _onSelected —
    // so listeners reading the BLoC state see the already-committed state.
    if (_currentProjectNotifier.currentProjectId != selectedProject.id) {
      _currentProjectNotifier.setCurrentProjectId(selectedProject.id);
    }
  }

  void _onProjectsLoadFailed(
    _ProjectDropdownProjectsLoadFailed event,
    Emitter<ProjectDropdownState> emit,
  ) {
    final currentState = state;
    emit(ProjectDropdownLoadFailure(
      failure: event.failure,
      cachedProjects: currentState is ProjectDropdownLoadSuccess
          ? currentState.projects.toList()
          : [],
      searchQuery: currentState is ProjectDropdownLoadSuccess
          ? currentState.searchQuery
          : '',
    ));
  }

  void _onSearchChanged(
    ProjectDropdownSearchChanged event,
    Emitter<ProjectDropdownState> emit,
  ) {
    final currentState = state;
    if (currentState is ProjectDropdownLoadSuccess) {
      if (currentState.searchQuery == event.query) return;
      emit(currentState.copyWith(searchQuery: event.query));
      return;
    }
  }

  void _onSelected(
    ProjectDropdownSelected event,
    Emitter<ProjectDropdownState> emit,
  ) {
    final currentState = state;
    if (currentState is! ProjectDropdownLoadSuccess) {
      return;
    }

    if (currentState.projects.isEmpty) {
      return;
    }

    Project? selectedProject;
    for (final project in currentState.projects) {
      if (project.id == event.projectId) {
        selectedProject = project;
        break;
      }
    }

    if (selectedProject == null) {
      return;
    }

    if (currentState.selectedProject?.id == selectedProject.id) {
      return;
    }

    emit(currentState.copyWith(selectedProject: selectedProject));
    // Notifier is updated after emit — consistent with _onProjectsUpdated —
    // so listeners reading the BLoC state see the committed state.
    if (_currentProjectNotifier.currentProjectId != selectedProject.id) {
      _currentProjectNotifier.setCurrentProjectId(selectedProject.id);
    }
  }
}
