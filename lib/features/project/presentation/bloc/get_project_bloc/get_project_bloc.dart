import 'dart:async';

import 'package:construculator/features/project/domain/entities/project_header_data.dart';
import 'package:construculator/features/project/domain/usecases/get_project_header_usecase.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'get_project_event.dart';
part 'get_project_state.dart';

class GetProjectBloc extends Bloc<GetProjectEvent, GetProjectState> {
  final GetProjectHeaderUseCase _getProjectHeaderUseCase;
  final CurrentProjectNotifier _currentProjectNotifier;
  StreamSubscription<String?>? _projectSubscription;

  GetProjectBloc({
    required GetProjectHeaderUseCase getProjectHeaderUseCase,
    required CurrentProjectNotifier currentProjectNotifier,
  }) : _getProjectHeaderUseCase = getProjectHeaderUseCase,
       _currentProjectNotifier = currentProjectNotifier,
       super(GetProjectInitial()) {
    on<GetProjectWatchStarted>(_onWatchStarted);
    on<GetProjectByIdLoadRequested>(_onProjectLoadRequested);
    on<GetProjectByIdRefreshRequested>(_onProjectRefreshRequested);
    on<_GetProjectCurrentProjectChanged>(_onCurrentProjectChanged);
  }

  void _onWatchStarted(
    GetProjectWatchStarted event,
    Emitter<GetProjectState> emit,
  ) {
    final currentId = _currentProjectNotifier.currentProjectId;
    if (currentId != null && currentId.isNotEmpty) {
      add(GetProjectByIdLoadRequested(currentId));
    }

    _projectSubscription ??= _currentProjectNotifier.onCurrentProjectChanged
        .listen((id) => add(_GetProjectCurrentProjectChanged(id)));
  }

  Future<void> _onCurrentProjectChanged(
    _GetProjectCurrentProjectChanged event,
    Emitter<GetProjectState> emit,
  ) async {
    final projectId = event.projectId;
    if (projectId == null || projectId.isEmpty) return;
    await _fetchProject(projectId, emit);
  }

  Future<void> _onProjectLoadRequested(
    GetProjectByIdLoadRequested event,
    Emitter<GetProjectState> emit,
  ) async {
    final currentState = state;
    if (currentState is GetProjectByIdLoadSuccess &&
        currentState.project.id == event.projectId) {
      return;
    }
    await _fetchProject(event.projectId, emit);
  }

  Future<void> _onProjectRefreshRequested(
    GetProjectByIdRefreshRequested event,
    Emitter<GetProjectState> emit,
  ) async {
    await _fetchProject(event.projectId, emit);
  }

  Future<void> _fetchProject(
    String projectId,
    Emitter<GetProjectState> emit,
  ) async {
    emit(GetProjectByIdLoading());

    final result = await _getProjectHeaderUseCase(projectId);

    result.fold(
      (failure) {
        emit(GetProjectByIdLoadFailure(failure: failure));
      },
      (headerData) {
        emit(GetProjectByIdLoadSuccess(headerData: headerData));
      },
    );
  }

  @override
  Future<void> close() {
    _projectSubscription?.cancel();
    return super.close();
  }
}
