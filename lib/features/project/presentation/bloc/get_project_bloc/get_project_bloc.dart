import 'package:construculator/features/project/domain/usecases/get_project_usecase.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'get_project_event.dart';
part 'get_project_state.dart';

class GetProjectBloc extends Bloc<GetProjectEvent, GetProjectState> {
  final GetProjectUseCase _getProjectUseCase;

  GetProjectBloc({required GetProjectUseCase getProjectUseCase})
    : _getProjectUseCase = getProjectUseCase,
      super(GetProjectInitial()) {
    on<GetProjectByIdLoadRequested>(_onProjectLoadRequested);
  }

  Future<void> _onProjectLoadRequested(
    GetProjectByIdLoadRequested event,
    Emitter<GetProjectState> emit,
  ) async {
    emit(GetProjectByIdLoading());

    final result = await _getProjectUseCase(event.projectId);

    result.fold(
      (failure) {
        emit(GetProjectByIdLoadFailure(failure: failure));
      },
      (project) {
        emit(GetProjectByIdLoadSuccess(project: project));
      },
    );
  }
}
