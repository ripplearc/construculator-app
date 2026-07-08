// coverage:ignore-file
part of 'project_details_bloc.dart';

/// Base class for all project details states.
sealed class ProjectDetailsState extends Equatable {
  const ProjectDetailsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load has been requested.
class ProjectDetailsInitial extends ProjectDetailsState {
  const ProjectDetailsInitial();
}

/// The project is being fetched.
class ProjectDetailsLoading extends ProjectDetailsState {
  const ProjectDetailsLoading();
}

/// The project was fetched successfully.
class ProjectDetailsLoaded extends ProjectDetailsState {
  const ProjectDetailsLoaded({required this.project});

  /// The loaded project.
  final Project project;

  @override
  List<Object?> get props => [project];
}

/// The project failed to load.
class ProjectDetailsLoadFailure extends ProjectDetailsState {
  const ProjectDetailsLoadFailure(this.failure);

  /// The failure that occurred while loading.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
