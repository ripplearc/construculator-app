import 'dart:async';

import 'package:construculator/libraries/auth/check/check_finished_state_impl.dart';
import 'package:construculator/libraries/auth/check/check_state.dart';

/// [CheckFinishedStateImpl] whose value a test sets directly, with no
/// transition rules for events and results.
class FakeCheckFinishedState extends CheckFinishedStateImpl {
  final Completer<void> _whenFinishedAsked = Completer<void>();

  /// The events [sessionEventArrived] received, as the user ids it was given.
  final List<String?> arrivedEventUserIds = [];

  /// A fake that starts at [initial]. Tests that only need readers released
  /// start it at a finished value.
  FakeCheckFinishedState({CheckState initial = const Checking()}) {
    emit(initial);
  }

  /// Completes the first time a reader calls [whenFinished] or
  /// [whenFinishedFor], which tells a test that the reader is now holding back.
  Future<void> get whenFinishedAsked => _whenFinishedAsked.future;

  /// Sets the value, as a transition would.
  void emit(CheckState state) => setValue(state);

  @override
  Future<String?> whenFinished() {
    if (!_whenFinishedAsked.isCompleted) _whenFinishedAsked.complete();
    return super.whenFinished();
  }

  @override
  Future<bool> whenFinishedFor(String userId) {
    if (!_whenFinishedAsked.isCompleted) _whenFinishedAsked.complete();
    return super.whenFinishedFor(userId);
  }

  @override
  void sessionEventArrived({
    required String? userId,
    required bool sessionModuleAdded,
  }) => arrivedEventUserIds.add(userId);

  @override
  void settle({required CheckState result, required bool isNewestEvent}) {
    if (isNewestEvent) emit(result);
  }
}
