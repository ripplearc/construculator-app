import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'project_details_event.dart';
part 'project_details_state.dart';

/// Loads the project shown on the [ProjectDetailScreen].
///
/// Fetches the [Project] by id through the shared [ProjectRepository]. Cost
/// estimation and member counts, and attached cost files, are not wired yet —
/// see the TODOs on [ProjectDetailScreen].
class ProjectDetailsBloc
    extends Bloc<ProjectDetailsEvent, ProjectDetailsState> {
  final ProjectRepository _projectRepository;

  ProjectDetailsBloc({required this._projectRepository})
    : super(const ProjectDetailsInitial()) {
    on<ProjectDetailsStarted>(_onStarted);
    on<ProjectDetailsRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    ProjectDetailsStarted event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProjectDetailsLoaded &&
        currentState.project.id == event.projectId) {
      return;
    }
    await _fetchProject(event.projectId, emit);
  }

  Future<void> _onRefreshed(
    ProjectDetailsRefreshed event,
    Emitter<ProjectDetailsState> emit,
  ) async {
    await _fetchProject(event.projectId, emit);
  }

  Future<void> _fetchProject(
    String projectId,
    Emitter<ProjectDetailsState> emit,
  ) async {
    emit(const ProjectDetailsLoading());
    try {
      final project = await _projectRepository.getProject(projectId);
      emit(ProjectDetailsLoaded(project: project));
    } on Failure catch (failure) {
      // The repository maps and logs errors at the boundary, then throws a
      // typed [Failure]; pass it through so the UI can distinguish causes.
      emit(ProjectDetailsLoadFailure(failure));
    } catch (_) {
      emit(ProjectDetailsLoadFailure(UnexpectedFailure()));
    }
  }
}
