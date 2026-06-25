part of 'create_project_bloc.dart';

/// Base event for [CreateProjectBloc].
abstract class CreateProjectEvent extends Equatable {
  const CreateProjectEvent();

  @override
  List<Object?> get props => [];
}

/// Submits [project] for creation.
class CreateProjectSubmitted extends CreateProjectEvent {
  /// The project to create.
  final Project project;

  const CreateProjectSubmitted(this.project);

  @override
  List<Object?> get props => [project];
}
