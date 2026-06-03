import 'dart:async';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'project_settings_event.dart';
part 'project_settings_state.dart';

/// Manages [ProjectSettingRepository] operations and exposes states for
/// loading, editing, saving, deleting, and error scenarios.
class ProjectSettingsBloc
    extends Bloc<ProjectSettingsEvent, ProjectSettingsState> {
  final ProjectSettingRepository _repository;
  StreamSubscription<Either<Failure, Project>>? _subscription;

  ProjectSettingsBloc({required ProjectSettingRepository repository})
      : _repository = repository,
        super(const ProjectSettingsInitial()) {
    on<ProjectSettingsWatchStarted>(_onWatchStarted);
    on<ProjectSettingsEditingStarted>(_onEditingStarted);
    on<ProjectSettingsUpdateSubmitted>(_onUpdateSubmitted);
    on<ProjectSettingsDeleteRequested>(_onDeleteRequested);
    on<_ProjectSettingsStreamUpdated>(_onStreamUpdated);
  }

  Future<void> _onWatchStarted(
    ProjectSettingsWatchStarted event,
    Emitter<ProjectSettingsState> emit,
  ) async {
    emit(const ProjectSettingsLoading());
    await _subscription?.cancel();
    _subscription = _repository
        .watchProjectSetting(event.projectId)
        .listen(
          (result) => add(_ProjectSettingsStreamUpdated(result)),
          onError: (Object error) => add(
            _ProjectSettingsStreamUpdated(Left(UnexpectedFailure())),
          ),
        );
  }

  void _onEditingStarted(
    ProjectSettingsEditingStarted event,
    Emitter<ProjectSettingsState> emit,
  ) {}

  Future<void> _onUpdateSubmitted(
    ProjectSettingsUpdateSubmitted event,
    Emitter<ProjectSettingsState> emit,
  ) async {}

  Future<void> _onDeleteRequested(
    ProjectSettingsDeleteRequested event,
    Emitter<ProjectSettingsState> emit,
  ) async {}

  void _onStreamUpdated(
    _ProjectSettingsStreamUpdated event,
    Emitter<ProjectSettingsState> emit,
  ) {}

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
