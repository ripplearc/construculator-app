// coverage:ignore-file

part of 'rename_estimation_bloc.dart';

/// Base class for all states emitted by the rename estimation BLoC.
///
/// States represent different phases of the rename operation:
/// - Initial state when the BLoC is created
/// - In-progress state when the rename operation is executing
/// - Success state when the rename operation completes successfully
/// - Failure state when the rename operation encounters an error
///
/// The UI listens to state emissions and rebuilds accordingly.
abstract class RenameEstimationState extends Equatable {
  final bool isSaveEnabled;

  const RenameEstimationState({required this.isSaveEnabled});

  @override
  List<Object> get props => [isSaveEnabled];
}

class RenameEstimationInitial extends RenameEstimationState {
  const RenameEstimationInitial({super.isSaveEnabled = false});
}

class RenameEstimationInProgress extends RenameEstimationState {
  const RenameEstimationInProgress({required super.isSaveEnabled});
}

class RenameEstimationSuccess extends RenameEstimationState {
  final String newName;

  const RenameEstimationSuccess(this.newName) : super(isSaveEnabled: false);

  @override
  List<Object> get props => [newName, isSaveEnabled];
}

class RenameEstimationFailure extends RenameEstimationState {
  final Failure failure;

  const RenameEstimationFailure(this.failure, {required super.isSaveEnabled});

  @override
  List<Object> get props => [failure, isSaveEnabled];
}

class RenameEstimationEditing extends RenameEstimationState {
  const RenameEstimationEditing({required super.isSaveEnabled});
}
