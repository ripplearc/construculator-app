import 'dart:convert';

import 'package:async/async.dart';
import 'package:construculator/libraries/calculation/data/data_source/powersync_local_calculation_session_data_source.dart';
import 'package:construculator/libraries/calculation/data/models/tape_chip_codec.dart';
import 'package:construculator/libraries/calculation/data/repositories/calculation_session_repository_impl.dart';
import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_calculation_sessions_database.dart';

void main() {
  late FakeCalculationSessionsDatabase database;
  late PowerSyncLocalCalculationSessionDataSource dataSource;
  late FakeSupabaseWrapper supabase;
  late FakeClockImpl clock;
  late CalculationSessionRepositoryImpl repository;
  final banked = DateTime.utc(2026, 11, 25, 9, 30);

  Matcher isRight(Object? value) => predicate<Either<Failure, Object?>>(
    (result) => result.fold((_) => false, (v) => v == value),
    'Right($value)',
  );

  Matcher isLeft(CalculatorErrorType errorType) =>
      predicate<Either<Failure, Object?>>(
        (result) => result.fold(
          (f) => f == CalculatorFailure(errorType: errorType),
          (_) => false,
        ),
        'Left(CalculatorFailure($errorType))',
      );

  final notFound = isLeft(CalculatorErrorType.notFound);
  final notSignedIn = isLeft(CalculatorErrorType.notSignedIn);
  final storageError = isLeft(CalculatorErrorType.storageError);

  Tape pressed(String keys) {
    var tape = const Tape();
    for (final key in keys.split(' ')) {
      final outcome = switch (key) {
        'ft' => tape.pressUnit(Unit.foot),
        'in' => tape.pressUnit(Unit.inch),
        '×' => tape.pressOperator(Operator.multiply),
        '+' => tape.pressOperator(Operator.add),
        '=' => tape.pressEquals(),
        '(' => tape.pressBracket(),
        _ when key.startsWith('[') => tape.pressFunctionKey(
          key.substring(1, key.length - 1),
        ),
        _ => tape.typeDigit(key),
      };
      tape = (outcome as TapeChanged).tape;
    }
    return tape;
  }

  Tape rectangle() {
    final typed = pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in');
    final area = const DeterministicRules()
        .answersFor(typed.namedValues)
        .firstWhere((answer) => answer.key == 'Area');
    return Tape(
      chips: [
        ...typed.chips,
        ResultChip(key: 'Area', value: area.value),
      ],
      preferences: typed.preferences,
    );
  }

  T right<T>(Either<Failure, T> either) =>
      either.fold((failure) => throw StateError('$failure'), (value) => value);

  setUp(() {
    database = FakeCalculationSessionsDatabase();
    dataSource = PowerSyncLocalCalculationSessionDataSource(database: database);
    clock = FakeClockImpl(banked);
    supabase = FakeSupabaseWrapper(clock: clock)..setInternalUserId('user-1');
    repository = CalculationSessionRepositoryImpl(
      dataSource: dataSource,
      supabaseWrapper: supabase,
      clock: clock,
    );
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
    supabase.dispose();
  });

  group('CalculationSessionRepositoryImpl', () {
    test('banking a tape that ends on a result keeps the result, its text '
        'and the whole tape, stamped now, under the signed-in user', () async {
      final tape = rectangle();
      final session = right(await repository.bankSession(tape));
      expect(session.creatorUserId, 'user-1');
      expect(session.title, isNull);
      expect(session.resultText, '410.67ft²');
      expect(
        session.result,
        isA<Area>().having((area) => area.unit, 'unit', Unit.foot),
      );
      expect(session.createdAt, banked);
      expect(session.updatedAt, banked);
      expect(session.lastCalculationAt, banked);
      expect(await repository.watchSessions().first, [session]);

      final row = database.tables['calculator_tapes']!.single;
      expect(row['session_id'], session.id);
      expect(row['schema_version'], TapeChipCodec.schemaVersion);
      final json = jsonDecode(row['computation'] as String);
      expect(
        [for (final chip in json['chips'] as List) chip['text']],
        ['22ft', '18ft 8in', '410.67ft²'],
      );
      expect(TapeChipCodec.decode(row['computation'] as String), tape.chips);
    });

    test('a tape banked without a result, or ending on an operator, a '
        'bracket or an error, has no result text (term 2.19, "Not '
        'finished"), and every chip still carries its text', () async {
      for (final (tape, texts) in [
        (pressed('[Length] 2 2 ft'), ['22ft']),
        (pressed('2 + 3 ×'), ['2', '+3', '×']),
        (pressed('2 + ( 3'), ['2', '+(3']),
      ]) {
        final session = right(
          await repository.bankSession(tape, title: 'Draft'),
        );
        expect(session.resultText, isNull, reason: texts.join(' '));
        expect(session.result, isNull);
        expect(session.title, 'Draft');
        final row = database.tables['calculator_tapes']!.last;
        final json = jsonDecode(row['computation'] as String);
        expect([for (final chip in json['chips'] as List) chip['text']], texts);
      }
    });

    test('banking an empty tape is a session with no result and an empty '
        'chip list in its row', () async {
      final session = right(await repository.bankSession(const Tape()));
      expect(session.result, isNull);
      expect(session.resultText, isNull);
      expect(session.title, isNull);
      final row = database.tables['calculator_tapes']!.single;
      expect(jsonDecode(row['computation'] as String)['chips'], isEmpty);
      final restored = right(
        await repository.restoreTape(
          session.id,
          preferences: CalculatorPreferences.defaults,
        ),
      );
      expect(restored.chips, isEmpty);
    });

    test('the same tape banked twice is two sessions with their own ids, '
        'both listed', () async {
      final tape = pressed('2 + 3 =');
      final first = right(await repository.bankSession(tape));
      final second = right(await repository.bankSession(tape));
      expect(first.id, isNot(second.id));
      expect(
        (await repository.watchSessions().first).map((s) => s.id),
        containsAll([first.id, second.id]),
      );
      expect(database.tables['calculator_sessions'], hasLength(2));
      expect(database.tables['calculator_tapes'], hasLength(2));
    });

    test('a result that an operator and a number continue is not the '
        'session\'s result: the chain is not finished', () async {
      final session = right(
        await repository.bankSession(pressed('2 + 3 = + 4')),
      );
      expect(session.resultText, isNull);
      expect(session.result, isNull);
    });

    test('a banked tape is restored chip for chip under the settings in '
        'force now, and the settings never change a stored value (rule '
        '4.14)', () async {
      final tape = rectangle();
      final session = right(await repository.bankSession(tape));
      const metric = CalculatorPreferences(system: MeasurementSystem.metric);
      final restored = right(
        await repository.restoreTape(session.id, preferences: metric),
      );
      expect(restored.chips, tape.chips);
      expect(restored.preferences, metric);
      expect(
        restored.chips.last,
        ResultChip(key: 'Area', value: session.result!),
      );
    });

    test('the watch lists the signed-in user\'s sessions newest first, and '
        'follows a bank, a rename and a delete', () async {
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(repository.watchSessions());
      expect(await events.next, isEmpty);
      final first = right(await repository.bankSession(pressed('2 + 3 =')));
      expect(await events.next, [first]);
      clock.advance(const Duration(minutes: 1));
      final second = right(await repository.bankSession(pressed('4 × 5 =')));
      expect(await events.next, [second, first]);
      clock.advance(const Duration(minutes: 1));
      expect(await repository.renameSession(first.id, 'Hall'), isRight(null));
      final renamed = await events.next;
      expect(renamed.map((s) => s.title), ['Hall', null].reversed);
      expect(renamed.last.updatedAt, banked.add(const Duration(minutes: 2)));
      expect(await repository.deleteSession(second.id), isRight(null));
      expect((await events.next).map((s) => s.id), [first.id]);
      await events.cancel();
    });

    test('getSession and search read the signed-in user\'s sessions; a '
        'session that is gone is notFound', () async {
      final session = right(
        await repository.bankSession(pressed('2 + 3 ='), title: 'Hall'),
      );
      expect(await repository.getSession(session.id), isRight(session));
      expect(right(await repository.search('hall')), [session]);
      expect(right(await repository.search('garage')), isEmpty);
      expect(await repository.getSession('ghost'), notFound);
      expect(await repository.renameSession('ghost', 'Hall'), notFound);
      expect(await repository.deleteSession('ghost'), notFound);
      expect(
        await repository.restoreTape(
          'ghost',
          preferences: CalculatorPreferences.defaults,
        ),
        notFound,
      );
    });

    test('nobody signed in: the watch is empty, even over a row left on the '
        'phone with no owner, and a bank or a search is refused as '
        'notSignedIn without a write', () async {
      right(await repository.bankSession(pressed('2 + 3 =')));
      database.tables['calculator_sessions']!.single['creator_user_id'] = '';
      supabase.setInternalUserId(null);
      expect(await repository.watchSessions().first, isEmpty);
      expect(await repository.bankSession(pressed('2 + 3 =')), notSignedIn);
      expect(await repository.search('hall'), notSignedIn);
      expect(database.tables['calculator_sessions']!, hasLength(1));
    });

    test('another user\'s sessions are not listed, and a session banked '
        'before sign-out is still there once the same user is back', () async {
      final mine = right(await repository.bankSession(pressed('2 + 3 =')));
      supabase.setInternalUserId('user-2');
      expect(await repository.watchSessions().first, isEmpty);
      right(await repository.bankSession(pressed('4 × 5 =')));
      supabase.setInternalUserId(null);
      expect(await repository.watchSessions().first, isEmpty);
      supabase.setInternalUserId('user-1');
      expect(await repository.watchSessions().first, [mine]);
    });

    test(
      'a session deleted once is gone: deleting it again is notFound',
      () async {
        final session = right(await repository.bankSession(pressed('2 + 3 =')));
        expect(await repository.deleteSession(session.id), isRight(null));
        expect(await repository.deleteSession(session.id), notFound);
        expect(await repository.getSession(session.id), notFound);
      },
    );

    test('a session whose tape row is gone still reads, but its tape is '
        'notFound', () async {
      final session = right(await repository.bankSession(pressed('2 + 3 =')));
      database.tables['calculator_tapes']!.removeWhere(
        (row) => row['session_id'] == session.id,
      );
      expect(await repository.getSession(session.id), isRight(session));
      expect(
        await repository.restoreTape(
          session.id,
          preferences: CalculatorPreferences.defaults,
        ),
        notFound,
      );
    });

    test('a session row this build cannot read is a storageError', () async {
      final session = right(await repository.bankSession(pressed('2 + 3 =')));
      database.tables['calculator_sessions']!.single['created_at'] = 'x';
      expect(await repository.getSession(session.id), storageError);
      expect(await repository.search(''), storageError);
    });

    test('a tape this build cannot read is notFound, so it is never '
        'half-restored', () async {
      final session = right(await repository.bankSession(pressed('2 + 3 =')));
      final row = database.tables['calculator_tapes']!.single;
      row['computation'] = '{"schema_version":2,"chips":[]}';
      row['schema_version'] = 2;
      expect(
        await repository.restoreTape(
          session.id,
          preferences: CalculatorPreferences.defaults,
        ),
        notFound,
      );
      row['computation'] = 'not json';
      expect(
        await repository.restoreTape(
          session.id,
          preferences: CalculatorPreferences.defaults,
        ),
        notFound,
      );
    });

    test('what the store throws is a storageError', () async {
      final session = right(await repository.bankSession(pressed('2 + 3 =')));
      database.writeError = StateError('full');
      expect(await repository.bankSession(pressed('2 + 3 =')), storageError);
      expect(await repository.renameSession(session.id, 'Hall'), storageError);
      expect(await repository.deleteSession(session.id), storageError);
      database.writeError = null;
      database.readError = StateError('locked');
      expect(await repository.getSession(session.id), storageError);
      expect(await repository.search('hall'), storageError);
      expect(
        await repository.restoreTape(
          session.id,
          preferences: CalculatorPreferences.defaults,
        ),
        storageError,
      );
    });

    test('dispose ends the watches handed out', () async {
      final sessions = repository.watchSessions();
      final ended = expectLater(
        sessions,
        emitsInOrder([<CalculationSession>[], emitsDone]),
      );
      await expectLater(sessions, emits(<CalculationSession>[]));
      repository.dispose();
      await ended;
    });

    test('dispose completes without throwing when the store refuses to let '
        'a watch go, and the watch still ends', () async {
      final sessions = repository.watchSessions();
      final ended = expectLater(
        sessions,
        emitsInOrder([<CalculationSession>[], emitsDone]),
      );
      await expectLater(sessions, emits(<CalculationSession>[]));
      database.cancelError = StateError('busy');
      expect(repository.dispose, returnsNormally);
      await ended;
      database.cancelError = null;
    });
  });
}
