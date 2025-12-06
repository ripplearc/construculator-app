// coverage:ignore-file
part of 'get_project_bloc.dart';

/// Base class for all Get Project states.
sealed class GetProjectState extends Equatable {
  const GetProjectState();

  @override
  List<Object?> get props => [];
}

class GetProjectInitial extends GetProjectState {
  @override
  List<Object?> get props => [];
}

class GetProjectByIdLoading extends GetProjectState {
  @override
  List<Object?> get props => [];
}

class GetProjectByIdLoadSuccess extends GetProjectState {
  final Project project;

  const GetProjectByIdLoadSuccess({required this.project});

  @override
  List<Object?> get props => [project];
}

class GetProjectByIdLoadFailure extends GetProjectState {
  final Failure failure;

  const GetProjectByIdLoadFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
