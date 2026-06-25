part of 'create_project_bloc.dart';

/// Base state for [CreateProjectBloc].
abstract class CreateProjectState extends Equatable {
  const CreateProjectState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any creation has been requested.
class CreateProjectInitial extends CreateProjectState {
  const CreateProjectInitial();
}

/// Emitted while a create request is in flight.
class CreateProjectInProgress extends CreateProjectState {
  const CreateProjectInProgress();
}

/// Emitted when the project is successfully created.
class CreateProjectSuccess extends CreateProjectState {
  /// The created project as persisted.
  final Project project;

  const CreateProjectSuccess({required this.project});

  @override
  List<Object?> get props => [project];
}

/// Emitted when project creation fails.
class CreateProjectFailure extends CreateProjectState {
  /// The failure describing what went wrong.
  final Failure failure;

  const CreateProjectFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
