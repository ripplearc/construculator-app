import 'dart:collection';
import 'dart:async';

import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'project_dropdown_event.dart';
part 'project_dropdown_state.dart';

class ProjectDropdownBloc
    extends Bloc<ProjectDropdownEvent, ProjectDropdownState> {
  final ProjectRepository _projectRepository;
  StreamSubscription<List<Project>>? _projectsSubscription;

  ProjectDropdownBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(const ProjectDropdownInitial()) {
    on<ProjectDropdownStarted>(_onStarted);
    on<ProjectDropdownSelected>(_onSelected);
    on<_ProjectDropdownProjectsUpdated>(_onProjectsUpdated);
    on<_ProjectDropdownProjectsLoadFailed>(_onProjectsLoadFailed);
  }

  @override
  Future<void> close() {
    _projectsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    ProjectDropdownStarted event,
    Emitter<ProjectDropdownState> emit,
  ) async {
    emit(const ProjectDropdownLoadInProgress());

    await _projectsSubscription?.cancel();
    _projectsSubscription = _projectRepository.watchProjects().listen(
      (projects) => add(_ProjectDropdownProjectsUpdated(projects)),
      onError: (Object error, StackTrace stackTrace) {
        add(_ProjectDropdownProjectsLoadFailed(error.toString()));
      },
    );
  }

  void _onProjectsUpdated(
    _ProjectDropdownProjectsUpdated event,
    Emitter<ProjectDropdownState> emit,
  ) {
    if (event.projects.isEmpty) {
      emit(
        ProjectDropdownLoadSuccess(projects: const [], selectedProject: null),
      );
      return;
    }

    final currentState = state;
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
      ),
    );
  }

  void _onProjectsLoadFailed(
    _ProjectDropdownProjectsLoadFailed event,
    Emitter<ProjectDropdownState> emit,
  ) {
    emit(ProjectDropdownLoadFailure(event.message));
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
  }
}
