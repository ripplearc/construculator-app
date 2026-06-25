import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_project_event.dart';
part 'create_project_state.dart';

/// Manages [ProjectSettingRepository.createProject] and exposes states for
/// the in-progress, success, and failure outcomes of project creation.
class CreateProjectBloc extends Bloc<CreateProjectEvent, CreateProjectState> {
  final ProjectSettingRepository _repository;

  CreateProjectBloc({required ProjectSettingRepository repository})
      : _repository = repository,
        super(const CreateProjectInitial()) {
    on<CreateProjectSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    CreateProjectSubmitted event,
    Emitter<CreateProjectState> emit,
  ) async {
    // Diverges from DASH-023: CreateProjectWithMembersUseCase (validation +
    // transaction + addMembers) deferred until the Members Module exists.
    emit(const CreateProjectInProgress());
    final result = await _repository.createProject(event.project);
    result.fold(
      (failure) => emit(CreateProjectFailure(failure: failure)),
      (project) => emit(CreateProjectSuccess(project: project)),
    );
  }
}
