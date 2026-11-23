import 'package:construculator/libraries/auth/check/check_state.dart';

/// The one place that says which user's data readers may read.
abstract class ActiveUserProvider {
  /// The user whose check finished, or null while a check runs, after a
  /// failure, and when nobody is signed in.
  String? get activeUserId;

  /// Completes with the signed-in user, or null when nobody is signed in, once
  /// the check has a finished value. Never completes after [RestartRequired].
  Future<String?> whenFinished();

  /// Completes with true once the check has finished for [userId], and with
  /// false when the state is closed first. Unlike [whenFinished] it ignores a
  /// finished value for anyone else, so a value left over from an earlier user
  /// never answers for [userId].
  Future<bool> whenFinishedFor(String userId);
}

/// Owns the check-finished state and its transition rules.
///
/// It starts as [Checking], before the first screen. It holds back
/// `authenticated` only, never `unauthenticated`.
abstract class CheckFinishedState implements ActiveUserProvider {
  /// The current value.
  CheckState get value;

  /// Emits every change of [value], and the current value to a new listener.
  Stream<CheckState> get changes;

  /// Tells the state that a session event arrived for [userId], or for nobody
  /// when [userId] is null.
  ///
  /// An event for another user, or for the same user while the session module
  /// is not added ([sessionModuleAdded] false), moves the state to [Checking]
  /// at once. A token renewal for the active user changes nothing. A [Blocked]
  /// state ignores the event, and [RestartRequired] is final.
  void sessionEventArrived({
    required String? userId,
    required bool sessionModuleAdded,
  });

  /// Ends a queue item. Sets [result], which must be [FinishedFor],
  /// [FinishedNobodySignedIn] or [Blocked], only when [isNewestEvent] is true;
  /// otherwise the state stays as it is for the next item.
  void settle({required CheckState result, required bool isNewestEvent});

  /// Sets [RestartRequired]. Nothing changes the state afterwards.
  void requireRestart();
}
