import 'dart:async';

import 'package:construculator/libraries/errors/expected_exception.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// How a queue item ended, as the settle step sees it.
enum QueueOutcome {
  /// The item finished its work.
  completed,

  /// The item threw.
  failed,

  /// An action of the item ran past the timeout.
  timedOut,
}

/// Thrown by [QueueRun.step] when an action runs past the timeout.
class QueueTimeoutException implements Exception {
  /// An error for an action that did not finish in time.
  const QueueTimeoutException();

  @override
  String toString() => 'QueueTimeoutException: an action ran past the timeout';
}

/// One run of a queue item.
///
/// Every side effect of the item (adding the module, connecting PowerSync,
/// setting the state, removing the flag) must check [isCurrent] first, because
/// a run that timed out can no longer do any of them.
class QueueRun {
  /// Identifies this run.
  final int id;

  final Duration _timeout;
  final void Function(Future<Object?> action) _onTimedOut;
  bool _timedOut = false;

  /// A run with [id] whose actions time out after [_timeout].
  QueueRun._(this.id, this._timeout, this._onTimedOut);

  /// Whether this run may still cause side effects.
  bool get isCurrent => !_timedOut;

  /// Runs [action] and returns its result.
  ///
  /// Throws a [QueueTimeoutException] when it takes longer than the timeout.
  /// The action is not cancelled: the queue treats it as still running until
  /// it ends.
  Future<T> step<T>(Future<T> Function() action) async {
    final running = action();
    try {
      return await running.timeout(_timeout);
    } on TimeoutException {
      _timedOut = true;
      _onTimedOut(running);
      throw const QueueTimeoutException();
    }
  }
}

/// Runs sign-in events, sign-out events and recovery one at a time.
///
/// A second item waits for the first. Each item gets a [QueueRun], every
/// action inside it has a timeout, and every item that starts ends with a
/// settle step, whatever the outcome. A new item starts only after an action
/// that timed out has stopped; while one has not, items are dropped without a
/// settle step and the unstopped-run callback is called instead.
class AuthEventQueue {
  final Duration _actionTimeout;
  final void Function() _onUnstoppedRun;
  final _logger = AppLogger().tag('AuthEventQueue');

  Future<void> _tail = Future<void>.value();
  Future<Object?>? _unstoppedAction;
  int _lastRunId = 0;
  int _lastEventNumber = 0;
  int _lastAcceptedEventNumber = 0;

  /// A queue whose actions time out after [actionTimeout].
  ///
  /// [onUnstoppedRun] is called instead of starting an item while an action
  /// that timed out is still running.
  AuthEventQueue({required this._actionTimeout, required this._onUnstoppedRun});

  /// The number of the newest event that arrived.
  int get newestEventNumber => _lastEventNumber;

  /// Gives the next event its number. Numbers only grow.
  int numberNextEvent() => ++_lastEventNumber;

  /// Whether the event with [eventNumber] is the newest that arrived.
  bool isNewest(int eventNumber) => eventNumber == _lastEventNumber;

  /// Adds the item for the event [eventNumber] and returns a future that
  /// completes when its settle step has ended. The future never completes with
  /// an error.
  ///
  /// An event number that is not newer than the last one added is ignored, so a
  /// replayed event is not handled twice.
  Future<void> enqueue({
    required int eventNumber,
    required Future<void> Function(QueueRun run) item,
    required Future<void> Function(QueueOutcome outcome) settle,
  }) {
    if (eventNumber <= _lastAcceptedEventNumber) return _tail;
    _lastAcceptedEventNumber = eventNumber;
    return _append(item, settle);
  }

  /// Adds an item that has no auth event of its own, such as start-up
  /// recovery, and returns a future that completes when its settle step has
  /// ended. The future never completes with an error.
  Future<void> enqueueWithoutEvent({
    required Future<void> Function(QueueRun run) item,
    required Future<void> Function(QueueOutcome outcome) settle,
  }) => _append(item, settle);

  Future<void> _append(
    Future<void> Function(QueueRun run) item,
    Future<void> Function(QueueOutcome outcome) settle,
  ) {
    final done = _tail.then((_) => _run(item, settle));
    _tail = done;
    return done;
  }

  Future<void> _run(
    Future<void> Function(QueueRun run) item,
    Future<void> Function(QueueOutcome outcome) settle,
  ) async {
    if (_unstoppedAction != null) {
      try {
        _onUnstoppedRun();
      } catch (error) {
        _logger.error('Reporting an unstopped run failed', error);
      }
      return;
    }
    // ignore: no_direct_instantiation, reason: per-item value holder, not a service
    final run = QueueRun._(++_lastRunId, _actionTimeout, _markUnstopped);
    var outcome = QueueOutcome.completed;
    try {
      await item(run);
    } on QueueTimeoutException {
      _logger.error('Queue item timed out in run ${run.id}');
      outcome = QueueOutcome.timedOut;
    } on ExpectedException catch (error) {
      _logger.warning('Queue item failed', error.runtimeType);
      outcome = QueueOutcome.failed;
    } catch (error) {
      _logger.error('Queue item failed', error.runtimeType);
      outcome = QueueOutcome.failed;
    }
    try {
      await settle(outcome);
    } catch (error) {
      _logger.error('Queue settle step failed', error.runtimeType);
    }
  }

  void _markUnstopped(Future<Object?> action) {
    _unstoppedAction = action;
    void markStopped(Object? _, [StackTrace? stackTrace]) {
      if (_unstoppedAction == action) _unstoppedAction = null;
    }

    action.then(markStopped, onError: markStopped);
  }
}
