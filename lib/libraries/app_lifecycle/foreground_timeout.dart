import 'dart:async';

import 'package:construculator/libraries/app_lifecycle/interfaces/app_lifecycle_wrapper.dart';

/// A [Future.timeout] that only counts time the app spends in the foreground.
extension ForegroundTimeout<T> on Future<T> {
  static const _tick = Duration(seconds: 1);

  /// Completes as this future does, or fails with a [TimeoutException] once
  /// the app has spent [limit] in the foreground without a result.
  ///
  /// Time in the background does not count, so a request left running while
  /// the contractor is in another app still gets its full [limit] when they
  /// come back. Foreground time is counted once a second, and going to the
  /// background drops the part of a second since the last count, so each
  /// trip away can lengthen the wait by up to a second.
  ///
  /// Like [Future.timeout], this only stops waiting; it does not cancel the
  /// underlying request. A retry may run beside the abandoned one, which is
  /// harmless for reads.
  Future<T> timeoutInForeground(
    Duration limit,
    AppLifecycleWrapper appLifecycle,
  ) {
    final result = Completer<T>();
    var foregroundTime = Duration.zero;
    Timer? ticker;

    void stopCounting() {
      ticker?.cancel();
      ticker = null;
    }

    void startCounting() {
      ticker ??= Timer.periodic(_tick, (_) {
        foregroundTime += _tick;
        if (foregroundTime >= limit && !result.isCompleted) {
          result.completeError(
            TimeoutException('No result after $limit in the foreground', limit),
          );
        }
      });
    }

    final subscription = appLifecycle.foregroundChanges.listen(
      (isInForeground) => isInForeground ? startCounting() : stopCounting(),
    );
    if (appLifecycle.isInForeground) startCounting();

    then(
      (value) {
        if (!result.isCompleted) result.complete(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!result.isCompleted) result.completeError(error, stackTrace);
      },
    );

    return result.future.whenComplete(() {
      stopCounting();
      return subscription.cancel();
    });
  }
}
