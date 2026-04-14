// coverage:ignore-file

part of 'change_lock_status_bloc.dart';

/// Base class for events that modify an estimation lock status.
abstract class ChangeLockStatusEvent extends Equatable {
  /// Creates a lock status event instance.
  const ChangeLockStatusEvent();

  /// Properties used to determine event equality.
  @override
  List<Object> get props => [];
}

/// This event will be dispatched when a user wants to lock or unlock an estimation
/// within a project. The lock status prevents or allows modifications to the estimation.
///
/// Parameters:
/// * [estimationId] - The unique identifier of the estimation whose lock status will be changed
/// * [isLocked] - The new lock status to be applied (true for locked, false for unlocked)
class ChangeLockStatusRequested extends ChangeLockStatusEvent {
  final String estimationId;
  final bool isLocked;

  const ChangeLockStatusRequested({
    required this.estimationId,
    required this.isLocked,
  });

  @override
  List<Object> get props => [estimationId, isLocked];
}
