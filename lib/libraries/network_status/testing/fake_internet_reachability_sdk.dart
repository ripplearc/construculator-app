import 'dart:async';

import 'package:construculator/libraries/network_status/interfaces/internet_reachability_sdk.dart';

/// [InternetReachabilitySdk] that a test drives by hand.
///
/// Answers that the internet can be reached until a test holds the checks and
/// releases them with another answer. Ticks are delivered synchronously.
class FakeInternetReachabilitySdk implements InternetReachabilitySdk {
  final _ticks = StreamController<void>.broadcast(sync: true);
  final _pendingChecks = <Completer<bool>>[];
  bool _isHolding = false;

  /// How many times [checkReachable] was called.
  int checkCount = 0;

  /// When true, [checkReachable] throws.
  bool shouldThrowOnCheck = false;

  @override
  Future<bool> checkReachable() {
    checkCount++;
    if (shouldThrowOnCheck) {
      return Future.error(StateError('reachability check failed'));
    }
    if (!_isHolding) return Future.value(true);
    final check = Completer<bool>();
    _pendingChecks.add(check);
    return check.future;
  }

  @override
  Stream<void> get checkTicks => _ticks.stream;

  /// Whether anything is listening to [checkTicks], that is, whether the timer
  /// would be running.
  bool get isPolling => _ticks.hasListener;

  /// Makes the timer tick once.
  void tick() => _ticks.add(null);

  /// Makes every [checkReachable] from now on wait until it is released.
  void holdChecks() => _isHolding = true;

  /// Lets the oldest waiting check finish with [reachable].
  ///
  /// Returns once whoever was waiting on that check has handled the answer.
  Future<void> releaseCheck(bool reachable) =>
      _release(_pendingChecks.removeAt(0), reachable);

  /// Lets the newest waiting check finish with [reachable].
  ///
  /// Returns once whoever was waiting on that check has handled the answer.
  Future<void> releaseNewestCheck(bool reachable) =>
      _release(_pendingChecks.removeLast(), reachable);

  Future<void> _release(Completer<bool> check, bool reachable) async {
    check.complete(reachable);
    await check.future;
  }

  /// Closes [checkTicks].
  void dispose() => unawaited(_ticks.close());
}
