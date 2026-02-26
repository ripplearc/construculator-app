import 'package:construculator/features/project/domain/entities/project_header_data.dart';
import 'package:construculator/features/project/domain/usecases/get_project_header_usecase.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'get_project_event.dart';
part 'get_project_state.dart';

class GetProjectBloc extends Bloc<GetProjectEvent, GetProjectState> {
  final GetProjectHeaderUseCase _getProjectHeaderUseCase;

  GetProjectBloc({required GetProjectHeaderUseCase getProjectHeaderUseCase})
    : _getProjectHeaderUseCase = getProjectHeaderUseCase,
      super(GetProjectInitial()) {
    on<GetProjectByIdLoadRequested>(_onProjectLoadRequested);
    on<GetProjectByIdRefreshRequested>(_onProjectRefreshRequested);
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
}
