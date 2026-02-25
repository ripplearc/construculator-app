// coverage:ignore-file

part of 'rename_estimation_bloc.dart';

/// Base class for all events triggered by the user or system for renaming estimations.
///
/// Events represent user intents or actions that trigger a state change in the BLoC.
/// All concrete events should extend this class and define their specific parameters.
abstract class RenameEstimationEvent extends Equatable {
  const RenameEstimationEvent();

  @override
  List<Object> get props => [];
}

class RenameEstimationTextChanged extends RenameEstimationEvent {
  final String text;

  const RenameEstimationTextChanged(this.text);

  @override
  List<Object> get props => [text];
}

class RenameEstimationRequested extends RenameEstimationEvent {
  final String estimationId;
  final String newName;
  final String projectId;

  const RenameEstimationRequested({
    required this.estimationId,
    required this.newName,
    required this.projectId,
  });

  @override
  List<Object> get props => [estimationId, newName, projectId];
}
