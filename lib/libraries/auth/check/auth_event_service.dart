import 'dart:async';

import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:construculator/libraries/auth/check/interfaces/check_finished_state.dart';
import 'package:construculator/libraries/auth/check/sign_in_check.dart';
import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Takes every Supabase auth event, tells the check-finished state about it
/// and handles it on the queue.
///
/// An event for a user other than the connected one stops PowerSync at once,
/// before it joins the queue. An event with a session runs the [SignInCheck]. Every item ends
/// with a settle step that sets the state from what is true by then: no
/// session gives [FinishedNobodySignedIn], a session whose module is added and
/// connected gives [FinishedFor], anything else gives [Blocked].
class AuthEventService implements Disposable {
  final SupabaseWrapper _wrapper;
  final AuthEventQueue _queue;
  final CheckFinishedState _state;
  final SignInCheck _signInCheck;
  final _logger = AppLogger().tag('AuthEventService');

  StreamSubscription<supabase.AuthState>? _subscription;
  (supabase.AuthChangeEvent, String?, String?)? _lastEvent;

  /// Starts listening to [wrapper] at once.
  AuthEventService({
    required this._wrapper,
    required this._queue,
    required this._state,
    required this._signInCheck,
  }) {
    _subscription = _wrapper.onAuthStateChange.listen(
      _onEvent,
      onError: (Object error) =>
          _logger.warning('Error in auth state stream', error.runtimeType),
    );
  }

  void _onEvent(supabase.AuthState event) {
    final session = event.session;
    final userId = session?.user.id;
    final key = (event.event, userId, session?.accessToken);
    if (key == _lastEvent) return;
    _lastEvent = key;

    _stopSyncingForOtherUser(userId);
    _state.sessionEventArrived(
      userId: userId,
      sessionModuleAdded: _signInCheck.activeModuleUserId == userId,
    );
    if (_state.value is Blocked || _state.value is RestartRequired) return;
    final number = _queue.numberNextEvent();
    unawaited(
      _queue.enqueue(
        eventNumber: number,
        item: (run) => _handle(run, event),
        settle: (outcome) => _settle(number, outcome),
      ),
    );
  }

  void _stopSyncingForOtherUser(String? userId) {
    final connectedUserId = _signInCheck.activeModuleUserId;
    if (connectedUserId == null || userId == connectedUserId) return;
    if (userId == null) return;
    unawaited(
      _signInCheck.stopSyncing().onError<Object>(
        (error, _) => _logger.warning(
          'Could not disconnect PowerSync for a different user',
          error.runtimeType,
        ),
      ),
    );
  }

  Future<void> _handle(QueueRun run, supabase.AuthState event) async {
    final userId = event.session?.user.id;
    if (userId == null) {
      // TODO: [CA-1462] Replace this clear with the sign-out handler, which
      // decides by the reason whether to delete or keep the data.
      // https://ripplearc.youtrack.cloud/issue/CA-1462
      await _signInCheck.clearAfterSignOut(run);
      return;
    }
    await _signInCheck.run(
      run,
      userId: userId,
      // TODO: [CA-1496] Take a fresh sign-in from the mark the Supabase wrapper
      // sets, not from the event name.
      // https://ripplearc.youtrack.cloud/issue/CA-1496
      isFreshSignIn: _isFreshSignInEvent(event.event),
    );
  }

  bool _isFreshSignInEvent(supabase.AuthChangeEvent event) =>
      event == supabase.AuthChangeEvent.signedIn ||
      event == supabase.AuthChangeEvent.passwordRecovery;

  Future<void> _settle(int eventNumber, QueueOutcome outcome) async {
    final signedInUserId = _wrapper.currentSession?.user.id;
    final CheckState result;
    if (signedInUserId == null) {
      result = const FinishedNobodySignedIn();
    } else if (outcome == QueueOutcome.completed &&
        _signInCheck.activeModuleUserId == signedInUserId) {
      result = FinishedFor(signedInUserId);
    } else {
      result = Blocked(signedInUserId);
    }
    _state.settle(result: result, isNewestEvent: _queue.isNewest(eventNumber));
  }

  @override
  void dispose() {
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }
}
