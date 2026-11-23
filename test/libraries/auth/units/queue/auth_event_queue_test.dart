import 'dart:async';

import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthEventQueue queue;
  late int unstoppedRunCalls;
  late List<String> log;

  setUp(() {
    unstoppedRunCalls = 0;
    log = [];
    // ignore: no_direct_instantiation, reason: unit test of the class itself
    queue = AuthEventQueue(
      actionTimeout: const Duration(milliseconds: 20),
      onUnstoppedRun: () => unstoppedRunCalls++,
    );
  });

  Future<void> noSettle(QueueOutcome outcome) async {}

  group('AuthEventQueue', () {
    test('a second item waits for the first to finish', () async {
      final firstGate = Completer<void>();
      final firstStarted = Completer<void>();

      final first = queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async {
          log.add('first starts');
          firstStarted.complete();
          await firstGate.future;
          log.add('first ends');
        },
        settle: noSettle,
      );
      final second = queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async => log.add('second runs'),
        settle: noSettle,
      );

      await firstStarted.future;
      expect(log, ['first starts']);

      firstGate.complete();
      await Future.wait([first, second]);

      expect(log, ['first starts', 'first ends', 'second runs']);
    });

    test('every item gets its own run id', () async {
      final ids = <int>[];

      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async => ids.add(run.id),
        settle: noSettle,
      );
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async => ids.add(run.id),
        settle: noSettle,
      );

      expect(ids, [1, 2]);
    });

    test('the settle step sees completed after a finished item', () async {
      QueueOutcome? seen;

      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async {},
        settle: (outcome) async => seen = outcome,
      );

      expect(seen, QueueOutcome.completed);
    });

    test('the settle step sees failed after an item that throws', () async {
      QueueOutcome? seen;

      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async => throw StateError('boom'),
        settle: (outcome) async => seen = outcome,
      );

      expect(seen, QueueOutcome.failed);
    });

    test('the settle step sees timedOut after a step runs too long', () async {
      QueueOutcome? seen;
      final neverEnds = Completer<void>();

      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) => run.step(() => neverEnds.future),
        settle: (outcome) async => seen = outcome,
      );

      expect(seen, QueueOutcome.timedOut);
    });

    test('a step returns the value of its action', () async {
      int? value;

      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async => value = await run.step(() async => 7),
        settle: noSettle,
      );

      expect(value, 7);
    });

    test('a run that timed out is no longer current', () async {
      late QueueRun timedOutRun;
      late bool wasCurrentBefore;
      final neverEnds = Completer<void>();

      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async {
          timedOutRun = run;
          wasCurrentBefore = run.isCurrent;
          await run.step(() => neverEnds.future);
        },
        settle: noSettle,
      );

      expect(wasCurrentBefore, isTrue);
      expect(timedOutRun.isCurrent, isFalse);
    });

    test('an item behind a running timed-out action is dropped and reported, '
        'then items run again once the action stops', () async {
      final neverEnds = Completer<void>();
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) => run.step(() => neverEnds.future),
        settle: noSettle,
      );

      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async => log.add('dropped item ran'),
        settle: noSettle,
      );

      expect(log, isEmpty);
      expect(unstoppedRunCalls, 1);

      neverEnds.complete();
      await neverEnds.future;
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async => log.add('later item ran'),
        settle: noSettle,
      );

      expect(log, ['later item ran']);
      expect(unstoppedRunCalls, 1);
    });

    test(
      'an unstopped-run callback that throws does not stop later items',
      () async {
        final neverEnds = Completer<void>();
        // ignore: no_direct_instantiation, reason: unit test of the class itself
        final throwing = AuthEventQueue(
          actionTimeout: const Duration(milliseconds: 20),
          onUnstoppedRun: () => throw StateError('report failed'),
        );
        await throwing.enqueue(
          eventNumber: throwing.numberNextEvent(),
          item: (run) => run.step(() => neverEnds.future),
          settle: noSettle,
        );
        await throwing.enqueue(
          eventNumber: throwing.numberNextEvent(),
          item: (run) async => log.add('dropped'),
          settle: noSettle,
        );

        neverEnds.complete();
        await neverEnds.future;
        await throwing.enqueue(
          eventNumber: throwing.numberNextEvent(),
          item: (run) async => log.add('later item ran'),
          settle: noSettle,
        );

        expect(log, ['later item ran']);
      },
    );

    test(
      'an event number that was already added is not handled twice',
      () async {
        final number = queue.numberNextEvent();

        await queue.enqueue(
          eventNumber: number,
          item: (run) async => log.add('handled'),
          settle: noSettle,
        );
        await queue.enqueue(
          eventNumber: number,
          item: (run) async => log.add('handled'),
          settle: noSettle,
        );

        expect(log, ['handled']);
      },
    );

    test('a settle step that throws does not stop the next item', () async {
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async {},
        settle: (outcome) async => throw StateError('settle failed'),
      );
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async => log.add('next item ran'),
        settle: noSettle,
      );

      expect(log, ['next item ran']);
    });

    test('event numbers grow and only the last one is the newest', () {
      final first = queue.numberNextEvent();
      final second = queue.numberNextEvent();

      expect(second, first + 1);
      expect(queue.newestEventNumber, second);
      expect(queue.isNewest(first), isFalse);
      expect(queue.isNewest(second), isTrue);
    });
  });
}
