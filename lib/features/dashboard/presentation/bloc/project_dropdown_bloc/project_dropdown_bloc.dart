import 'dart:collection';

import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'project_dropdown_event.dart';
part 'project_dropdown_state.dart';

class ProjectDropdownBloc
    extends Bloc<ProjectDropdownEvent, ProjectDropdownState> {
  final ProjectRepository _projectRepository;

  ProjectDropdownBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(const ProjectDropdownInitial()) {
    on<ProjectDropdownStarted>(_onStarted);
    on<ProjectDropdownSelected>(_onSelected);
  }

  Future<void> _onStarted(
    ProjectDropdownStarted event,
    Emitter<ProjectDropdownState> emit,
  ) async {
    await _loadProjects(emit);
  }

  Future<void> _loadProjects(Emitter<ProjectDropdownState> emit) async {
    emit(const ProjectDropdownLoadInProgress());

    final projects = await _projectRepository.getProjects();
    if (projects.isEmpty) {
      emit(
        ProjectDropdownLoadSuccess(projects: const [], selectedProject: null),
      );
      return;
    }

    emit(
      ProjectDropdownLoadSuccess(
        projects: projects,
        selectedProject: projects.first,
      ),
    );
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
