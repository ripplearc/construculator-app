import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'project_settings_event.dart';
part 'project_settings_state.dart';

/// Manages [ProjectSettingRepository] operations and exposes states for
/// loading, editing, saving, deleting, and error scenarios.
class ProjectSettingsBloc
    extends Bloc<ProjectSettingsEvent, ProjectSettingsState> {
  final ProjectSettingRepository _repository;

  ProjectSettingsBloc({required ProjectSettingRepository repository})
      : _repository = repository,
        super(const ProjectSettingsInitial()) {
    on<ProjectSettingsLoadRequested>(_onLoadRequested);
    on<ProjectSettingsEditingStarted>(_onEditingStarted);
    on<ProjectSettingsUpdateSubmitted>(_onUpdateSubmitted);
    on<ProjectSettingsDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    ProjectSettingsLoadRequested event,
    Emitter<ProjectSettingsState> emit,
  ) async {
    emit(const ProjectSettingsLoading());
    final result = await _repository.getProjectSetting(event.projectId);
    result.fold(
      (failure) => emit(ProjectSettingsError(failure: failure)),
      (project) => emit(ProjectSettingsLoaded(project)),
    );
  }

  void _onEditingStarted(
    ProjectSettingsEditingStarted event,
    Emitter<ProjectSettingsState> emit,
  ) {
    if (state is! ProjectSettingsLoaded) return;
    emit(
      ProjectSettingsEditing(
        project: event.project,
        originalProject: event.project,
      ),
    );
  }

  Future<void> _onUpdateSubmitted(
    ProjectSettingsUpdateSubmitted event,
    Emitter<ProjectSettingsState> emit,
  ) async {
    final currentState = state;
    final originalProject = currentState is ProjectSettingsEditing
        ? currentState.originalProject
        : event.project;

    emit(ProjectSettingsSaving(event.project));

    final result = await _repository.updateProject(event.project);
    result.fold(
      (failure) => emit(
        ProjectSettingsError(failure: failure, lastProject: originalProject),
      ),
      (updated) => emit(ProjectSettingsLoaded(updated)),
    );
  }

  Future<void> _onDeleteRequested(
    ProjectSettingsDeleteRequested event,
    Emitter<ProjectSettingsState> emit,
  ) async {
    final currentState = state;
    final lastProject = switch (currentState) {
      ProjectSettingsLoaded(:final project) => project,
      ProjectSettingsEditing(:final originalProject) => originalProject,
      _ => null,
    };

    emit(const ProjectSettingsDeleteInProgress());

    final result = await _repository.deleteProject(event.projectId);
    result.fold(
      (failure) => emit(
        ProjectSettingsError(failure: failure, lastProject: lastProject),
      ),
      (_) => emit(const ProjectSettingsInitial()),
    );
  }
}
