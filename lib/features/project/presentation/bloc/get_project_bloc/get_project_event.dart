// coverage:ignore-file
part of 'get_project_bloc.dart';

/// Base class for all Get Project events.
sealed class GetProjectEvent extends Equatable {
  const GetProjectEvent();

  @override
  List<Object> get props => [];
}

class GetProjectByIdLoadRequested extends GetProjectEvent {
  const GetProjectByIdLoadRequested(this.projectId);

  final String projectId;

  @override
  List<Object> get props => [projectId];
}
