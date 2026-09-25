import 'dart:async';

import 'package:construculator/libraries/app_lifecycle/foreground_timeout.dart';
import 'package:construculator/libraries/app_lifecycle/testing/fake_app_lifecycle_wrapper.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timeoutInForeground', () {
    const limit = Duration(seconds: 15);
    late FakeAppLifecycleWrapper appLifecycle;

    setUp(() {
      appLifecycle = FakeAppLifecycleWrapper();
    });

    // Starts a call that never answers, and records how it ends.
    ({Object? Function() error}) startStalledCall(FakeAsync async) {
      Object? error;
      unawaited(
        Completer<String>().future
            .timeoutInForeground(limit, appLifecycle)
            .then<void>((_) {}, onError: (Object e) => error = e),
      );
      async.flushMicrotasks();
      return (error: () => error);
    }

    test('completes with the value when it arrives in time', () {
      fakeAsync((async) {
        String? value;
        unawaited(
          Future<String>.delayed(
            const Duration(seconds: 3),
            () => 'logs',
          ).timeoutInForeground(limit, appLifecycle).then((v) => value = v),
        );

        async.elapse(const Duration(seconds: 3));

        expect(value, 'logs');
      });
    });

    test('passes on the error of a call that fails in time', () {
      fakeAsync((async) {
        Object? error;
        unawaited(
          Future<String>.error(const FormatException('bad row'))
              .timeoutInForeground(limit, appLifecycle)
              .then<void>((_) {}, onError: (Object e) => error = e),
        );

        async.flushMicrotasks();

        expect(error, isA<FormatException>());
      });
    });

    test('times out after the limit spent in the foreground', () {
      fakeAsync((async) {
        final call = startStalledCall(async);

        async.elapse(const Duration(seconds: 14));
        expect(call.error(), isNull);

        async.elapse(const Duration(seconds: 1));
        expect(
          call.error(),
          isA<TimeoutException>().having((e) => e.duration, 'duration', limit),
        );
      });
    });

    test('does not count time spent in the background', () {
      fakeAsync((async) {
        final call = startStalledCall(async);

        async.elapse(const Duration(seconds: 10));
        appLifecycle.setInForeground(false);
        async.elapse(const Duration(minutes: 5));
        expect(call.error(), isNull, reason: 'the background does not count');

        appLifecycle.setInForeground(true);
        async.elapse(const Duration(seconds: 4));
        expect(call.error(), isNull, reason: '14 of 15 foreground seconds');

        async.elapse(const Duration(seconds: 1));
        expect(call.error(), isA<TimeoutException>());
      });
    });

    test('waits for the foreground when started in the background', () {
      fakeAsync((async) {
        appLifecycle.setInForeground(false);
        final call = startStalledCall(async);

        async.elapse(const Duration(minutes: 5));
        expect(call.error(), isNull);

        appLifecycle.setInForeground(true);
        async.elapse(limit);
        expect(call.error(), isA<TimeoutException>());
      });
    });

    test('leaves no timer running once the call completes', () {
      fakeAsync((async) {
        unawaited(
          Future<String>.value('logs').timeoutInForeground(limit, appLifecycle),
        );
        async.flushMicrotasks();

        expect(async.periodicTimerCount, 0);

        appLifecycle.setInForeground(false);
        appLifecycle.setInForeground(true);
        expect(
          async.periodicTimerCount,
          0,
          reason: 'a completed call stops listening to the lifecycle',
        );
      });
    });
  });
}
