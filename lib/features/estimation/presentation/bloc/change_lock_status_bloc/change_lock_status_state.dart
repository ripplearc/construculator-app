part of 'change_lock_status_bloc.dart';

/// Base class for states emitted during lock status updates.
abstract class ChangeLockStatusState extends Equatable {
  /// Creates a lock status state instance.
  const ChangeLockStatusState();

  /// Properties used to determine state equality.
  @override
  List<Object> get props => [];
}

class ChangeLockStatusInitial extends ChangeLockStatusState {
  const ChangeLockStatusInitial();
}

class ChangeLockStatusInProgress extends ChangeLockStatusState {
  const ChangeLockStatusInProgress();
}

class ChangeLockStatusSuccess extends ChangeLockStatusState {
  final bool isLocked;

  const ChangeLockStatusSuccess(this.isLocked);

  @override
  List<Object> get props => [isLocked];
}

class ChangeLockStatusFailure extends ChangeLockStatusState {
  final Failure failure;

  const ChangeLockStatusFailure(this.failure);

  @override
  List<Object> get props => [failure];
}
