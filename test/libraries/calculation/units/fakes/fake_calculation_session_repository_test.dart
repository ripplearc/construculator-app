import 'package:async/async.dart';
import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculation/testing/fake_calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCalculationSessionRepository repository;

  Tape sum() {
    final typed = (const Tape().typeDigit('2') as TapeChanged).tape;
    final plus = (typed.pressOperator(Operator.add) as TapeChanged).tape;
    final three = (plus.typeDigit('3') as TapeChanged).tape;
    return (three.pressEquals() as TapeChanged).tape;
  }

  T right<T>(Either<Failure, T> either) =>
      either.fold((failure) => throw StateError('$failure'), (value) => value);

  Matcher isLeft(CalculatorErrorType errorType) =>
      predicate<Either<Failure, Object?>>(
        (result) => result.fold(
          (f) => f == CalculatorFailure(errorType: errorType),
          (_) => false,
        ),
        'Left(CalculatorFailure($errorType))',
      );

  setUp(() {
    repository = FakeCalculationSessionRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  group('FakeCalculationSessionRepository', () {
    test('banks a tape with a minted id, its result and text, newest first, '
        'and restores it under the settings asked for', () async {
      final first = right(await repository.bankSession(sum()));
      final second = right(await repository.bankSession(sum(), title: 'Again'));
      expect(first.id, 'session-1');
      expect(first.resultText, '5');
      expect(first.result, const Scalar(5));
      expect(first.creatorUserId, 'user-1');
      expect(second.title, 'Again');
      expect(repository.sessions, [second, first]);
      expect(repository.bankCallCount, 2);
      const metric = CalculatorPreferences(system: MeasurementSystem.metric);
      final restored = right(
        await repository.restoreTape(first.id, preferences: metric),
      );
      expect(restored.chips, sum().chips);
      expect(restored.preferences, metric);
    });

    test('the watch emits now and after a bank, a rename and a delete', () async {
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(repository.watchSessions());
      expect(await events.next, isEmpty);
      final session = right(await repository.bankSession(sum()));
      expect(await events.next, [session]);
      await repository.renameSession(session.id, 'Hall');
      expect((await events.next).single.title, 'Hall');
      await repository.deleteSession(session.id);
      expect(await events.next, isEmpty);
      expect(repository.tapes, isEmpty);
      await events.cancel();
    });

    test('getSession and search find what was banked; a session that is '
        'gone is notFound', () async {
      final session = right(await repository.bankSession(sum(), title: 'Hall'));
      expect(right(await repository.getSession(session.id)), session);
      expect(right(await repository.search('HALL')), [session]);
      expect(right(await repository.search('5')), [session]);
      expect(right(await repository.search('garage')), isEmpty);
      expect(
        await repository.getSession('ghost'),
        isLeft(CalculatorErrorType.notFound),
      );
      expect(
        await repository.renameSession('ghost', 'x'),
        isLeft(CalculatorErrorType.notFound),
      );
      expect(
        await repository.deleteSession('ghost'),
        isLeft(CalculatorErrorType.notFound),
      );
      expect(
        await repository.restoreTape(
          'ghost',
          preferences: CalculatorPreferences.defaults,
        ),
        isLeft(CalculatorErrorType.notFound),
      );
    });

    test('nobody signed in refuses a bank and a search and empties the '
        'watch; a write failure refuses every write', () async {
      repository.signedIn = false;
      expect(
        await repository.bankSession(sum()),
        isLeft(CalculatorErrorType.notSignedIn),
      );
      expect(
        await repository.search('a'),
        isLeft(CalculatorErrorType.notSignedIn),
      );
      expect(await repository.watchSessions().first, isEmpty);
      repository.signedIn = true;
      final session = right(await repository.bankSession(sum()));
      repository.writeFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );
      expect(
        await repository.bankSession(sum()),
        isLeft(CalculatorErrorType.storageError),
      );
      expect(
        await repository.renameSession(session.id, 'x'),
        isLeft(CalculatorErrorType.storageError),
      );
      expect(
        await repository.deleteSession(session.id),
        isLeft(CalculatorErrorType.storageError),
      );
      expect(repository.sessions, [session]);
    });

    test(
      'a session deleted once is gone: deleting it again is notFound',
      () async {
        final session = right(await repository.bankSession(sum()));
        expect((await repository.deleteSession(session.id)).isRight(), isTrue);
        expect(
          await repository.deleteSession(session.id),
          isLeft(CalculatorErrorType.notFound),
        );
        expect(repository.sessions, isEmpty);
      },
    );

    test('a write failure answers before a session is looked for: a ghost id '
        'is refused with the failure, not as notFound', () async {
      repository.writeFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );
      expect(
        await repository.renameSession('ghost', 'x'),
        isLeft(CalculatorErrorType.storageError),
      );
      expect(
        await repository.deleteSession('ghost'),
        isLeft(CalculatorErrorType.storageError),
      );
    });

    test('reset forgets the sessions, the tapes and the counters', () async {
      right(await repository.bankSession(sum()));
      repository.reset();
      expect(repository.sessions, isEmpty);
      expect(repository.tapes, isEmpty);
      expect(repository.bankCallCount, 0);
      expect(
        right(await repository.bankSession(sum())),
        isA<CalculationSession>().having((s) => s.id, 'id', 'session-1'),
      );
    });

    test('reset keeps the flags: nobody signed in and the write failure '
        'stay as set', () async {
      repository.signedIn = false;
      repository.writeFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );
      repository.reset();
      expect(repository.signedIn, isFalse);
      expect(
        repository.writeFailure,
        const CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
      expect(
        await repository.bankSession(sum()),
        isLeft(CalculatorErrorType.notSignedIn),
      );
    });

    test('dispose twice does not throw, and ends the watch', () async {
      final sessions = repository.watchSessions();
      final ended = expectLater(
        sessions,
        emitsInOrder([<CalculationSession>[], emitsDone]),
      );
      await expectLater(sessions, emits(<CalculationSession>[]));
      repository.dispose();
      expect(repository.dispose, returnsNormally);
      await ended;
    });
  });
}
