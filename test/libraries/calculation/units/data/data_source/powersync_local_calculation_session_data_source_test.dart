import 'package:async/async.dart';
import 'package:construculator/libraries/calculation/data/data_source/powersync_local_calculation_session_data_source.dart';
import 'package:construculator/libraries/calculation/data/models/calculation_session_dto.dart';
import 'package:construculator/libraries/calculation/data/models/calculation_tape_dto.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_calculation_sessions_database.dart';

void main() {
  late FakeCalculationSessionsDatabase database;
  late PowerSyncLocalCalculationSessionDataSource dataSource;
  final start = DateTime.utc(2026, 11, 25, 9);

  CalculationSessionDto session(
    int number, {
    String user = 'user-1',
    String? title,
    String? resultText = '410.67ft²',
  }) => CalculationSessionDto(
    id: 'session-$number',
    creatorUserId: user,
    title: title,
    resultText: resultText,
    result: resultText == null ? null : const Scalar(2),
    createdAt: start.add(Duration(minutes: number)),
    updatedAt: start.add(Duration(minutes: number)),
    lastCalculationAt: start.add(Duration(minutes: number)),
  );

  CalculationTapeDto tape(int number) => CalculationTapeDto(
    id: 'tape-$number',
    sessionId: 'session-$number',
    computation: '{"schema_version":1,"chips":[]}',
    schemaVersion: 1,
    createdAt: start.add(Duration(minutes: number)),
  );

  Future<void> bank(int number, {String user = 'user-1', String? title}) =>
      dataSource.insertSession(
        session(number, user: user, title: title),
        tape(number),
      );

  setUp(() {
    database = FakeCalculationSessionsDatabase();
    dataSource = PowerSyncLocalCalculationSessionDataSource(database: database);
  });

  tearDown(() async {
    await dataSource.dispose();
    await database.closeChanges();
  });

  group('PowerSyncLocalCalculationSessionDataSource', () {
    test('a user with nothing banked has no sessions and no session', () async {
      expect(await dataSource.watchSessions('user-1').first, isEmpty);
      expect(await dataSource.fetchSessionById('session-1'), isNull);
      expect(await dataSource.fetchTapeBySessionId('session-1'), isNull);
    });

    test('a banked session and its tape read back, newest first, and one '
        'user\'s sessions are kept apart from another\'s', () async {
      await bank(1);
      await bank(2);
      await bank(3, user: 'user-2');
      expect(await dataSource.watchSessions('user-1').first, [
        session(2),
        session(1),
      ]);
      expect(await dataSource.watchSessions('user-2').first, [
        session(3, user: 'user-2'),
      ]);
      expect(await dataSource.fetchSessionById('session-1'), session(1));
      expect(await dataSource.fetchTapeBySessionId('session-2'), tape(2));
    });

    test('a watch emits the list now and after a bank, a rename and a '
        'delete, the session and its tape arriving together', () async {
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(dataSource.watchSessions('user-1'));
      expect(await events.next, isEmpty);
      await bank(1);
      expect(await events.next, [session(1)]);
      expect(await dataSource.fetchTapeBySessionId('session-1'), tape(1));
      await dataSource.renameSession(
        'session-1',
        'Hall',
        start.add(const Duration(hours: 1)),
      );
      final renamed = await events.next;
      expect(renamed.single.title, 'Hall');
      expect(renamed.single.updatedAt, start.add(const Duration(hours: 1)));
      expect(renamed.single.lastCalculationAt, session(1).lastCalculationAt);
      await dataSource.deleteSession('session-1');
      expect(await events.next, isEmpty);
      expect(await dataSource.fetchTapeBySessionId('session-1'), isNull);
      await events.cancel();
    });

    test('renaming or deleting a session nobody has answers false and '
        'writes nothing', () async {
      expect(await dataSource.renameSession('ghost', 'Hall', start), isFalse);
      expect(await dataSource.deleteSession('ghost'), isFalse);
      expect(
        database.executed.where((sql) => !sql.startsWith('SELECT')),
        isEmpty,
      );
    });

    test('a session deleted once is gone: deleting it again or renaming it '
        'answers false', () async {
      await bank(1);
      expect(await dataSource.deleteSession('session-1'), isTrue);
      expect(await dataSource.deleteSession('session-1'), isFalse);
      expect(
        await dataSource.renameSession('session-1', 'Hall', start),
        isFalse,
      );
      expect(await dataSource.fetchSessionById('session-1'), isNull);
      expect(await dataSource.fetchTapeBySessionId('session-1'), isNull);
    });

    test('a store already past fifty sessions is brought back to fifty by '
        'the next bank, the oldest pruned with their tapes', () async {
      database.tables['calculator_sessions'] = [
        for (var number = 1; number <= 55; number++) session(number).toRow(),
      ];
      database.tables['calculator_tapes'] = [
        for (var number = 1; number <= 55; number++) tape(number).toRow(),
      ];
      await bank(56);
      final kept = await dataSource.watchSessions('user-1').first;
      expect(
        kept.length,
        PowerSyncLocalCalculationSessionDataSource.keptSessions,
      );
      expect(kept.first, session(56));
      expect(kept.last, session(7));
      expect(database.tables['calculator_tapes'], hasLength(50));
      for (var number = 1; number <= 6; number++) {
        expect(await dataSource.fetchSessionById('session-$number'), isNull);
        expect(
          await dataSource.fetchTapeBySessionId('session-$number'),
          isNull,
        );
      }
      expect(await dataSource.fetchTapeBySessionId('session-7'), tape(7));
    });

    test('the newest fifty sessions of a user are kept and the oldest are '
        'pruned with their tapes when one more is banked', () async {
      for (var number = 1; number <= 50; number++) {
        await bank(number);
      }
      await bank(99, user: 'user-2');
      expect(
        (await dataSource.watchSessions('user-1').first).length,
        PowerSyncLocalCalculationSessionDataSource.keptSessions,
      );
      await bank(51);
      final kept = await dataSource.watchSessions('user-1').first;
      expect(kept.length, 50);
      expect(kept.first, session(51));
      expect(kept.last, session(2));
      expect(await dataSource.fetchSessionById('session-1'), isNull);
      expect(await dataSource.fetchTapeBySessionId('session-1'), isNull);
      expect(await dataSource.fetchTapeBySessionId('session-2'), tape(2));
      expect(
        await dataSource.watchSessions('user-2').first,
        [session(99, user: 'user-2')],
        reason: 'another user\'s sessions are not pruned',
      );
    });

    test('a search matches the title or the result text, whatever the case, '
        'newest first and within its limit, and a % or _ in the query '
        'matches itself', () async {
      await bank(1, title: 'Hall drywall');
      await bank(2, title: 'Garage');
      await bank(3, title: 'Hall paint');
      await dataSource.insertSession(
        session(4, title: '50% done', resultText: 'Cost: \$12'),
        tape(4),
      );
      expect(await dataSource.searchSessions('user-1', 'hall'), [
        session(3, title: 'Hall paint'),
        session(1, title: 'Hall drywall'),
      ]);
      expect(
        (await dataSource.searchSessions('user-1', 'hall', limit: 1)).single,
        session(3, title: 'Hall paint'),
      );
      expect(
        (await dataSource.searchSessions('user-1', 'ft²')).map((s) => s.id),
        ['session-3', 'session-2', 'session-1'],
      );
      expect(
        (await dataSource.searchSessions('user-1', '50%')).map((s) => s.id),
        ['session-4'],
      );
      expect(await dataSource.searchSessions('user-1', 'a_l'), isEmpty);
      expect(await dataSource.searchSessions('user-2', 'hall'), isEmpty);
    });

    test('an empty query matches every session, and a backslash in a title '
        'is found by a backslash in the query', () async {
      await bank(1, title: 'Hall');
      await bank(2, title: r'Hall\stairs');
      await bank(3);
      expect((await dataSource.searchSessions('user-1', '')).map((s) => s.id), [
        'session-3',
        'session-2',
        'session-1',
      ]);
      expect(
        (await dataSource.searchSessions(
          'user-1',
          '',
          limit: 2,
        )).map((s) => s.id),
        ['session-3', 'session-2'],
      );
      expect(
        (await dataSource.searchSessions('user-1', r'\')).map((s) => s.id),
        ['session-2'],
      );
      expect(
        (await dataSource.searchSessions('user-1', r'l\s')).map((s) => s.id),
        ['session-2'],
      );
    });

    test('a search answers twenty sessions unless told otherwise, and none '
        'for a limit of zero', () async {
      for (var number = 1; number <= 25; number++) {
        await bank(number, title: 'Hall $number');
      }
      final found = await dataSource.searchSessions('user-1', 'hall');
      expect(found, hasLength(20));
      expect(found.first.id, 'session-25');
      expect(found.last.id, 'session-6');
      expect(
        await dataSource.searchSessions('user-1', 'hall', limit: 0),
        isEmpty,
      );
      expect(
        await dataSource.searchSessions('user-1', 'hall', limit: 30),
        hasLength(25),
      );
    });

    test(
      'a session whose tape row is gone still reads, with no tape',
      () async {
        await bank(1);
        database.tables['calculator_tapes']!.removeWhere(
          (row) => row['session_id'] == 'session-1',
        );
        expect(await dataSource.fetchSessionById('session-1'), session(1));
        expect(await dataSource.fetchTapeBySessionId('session-1'), isNull);
        expect(await dataSource.watchSessions('user-1').first, [session(1)]);
      },
    );

    test('a store that refuses a read while a watch is open hands the watch '
        'the refusal, and the tape read throws it too', () async {
      await bank(1);
      final sessions = dataSource.watchSessions('user-1');
      final watched = expectLater(
        sessions,
        emitsInOrder([
          [session(1)],
          emitsError(isStateError),
        ]),
      );
      await expectLater(sessions, emits([session(1)]));
      database.readError = StateError('locked');
      await expectLater(
        dataSource.fetchTapeBySessionId('session-1'),
        throwsStateError,
      );
      await expectLater(bank(2), throwsStateError);
      await watched;
      database.readError = null;
    });

    test('dispose twice does not throw', () async {
      final sessions = dataSource.watchSessions('user-1');
      await expectLater(sessions, emits(<CalculationSessionDto>[]));
      await dataSource.dispose();
      await dataSource.dispose();
      await bank(1);
      expect(await dataSource.fetchSessionById('session-1'), session(1));
    });

    test(
      'a read or a write the store refuses is thrown to the caller',
      () async {
        database.readError = StateError('locked');
        await expectLater(
          dataSource.fetchSessionById('session-1'),
          throwsStateError,
        );
        await expectLater(
          dataSource.searchSessions('user-1', 'hall'),
          throwsStateError,
        );
        database.readError = null;
        database.writeError = StateError('full');
        await expectLater(bank(1), throwsStateError);
        expect(await dataSource.watchSessions('user-1').first, isEmpty);
      },
    );

    test('dispose ends every watch handed out and leaves the store usable; a '
        'watch asked for afterwards answers once and ends', () async {
      final sessions = dataSource.watchSessions('user-1');
      final ended = expectLater(
        sessions,
        emitsInOrder([<CalculationSessionDto>[], emitsDone]),
      );
      await expectLater(sessions, emits(<CalculationSessionDto>[]));
      await dataSource.dispose();
      await ended;
      await bank(1);
      expect(await dataSource.watchSessions('user-1').toList(), [
        [session(1)],
      ]);
    });

    test('dispose closes a watch even when the store refuses to let it go, '
        'and throws the refusal', () async {
      final sessions = dataSource.watchSessions('user-1');
      final ended = expectLater(
        sessions,
        emitsInOrder([<CalculationSessionDto>[], emitsDone]),
      );
      await expectLater(sessions, emits(<CalculationSessionDto>[]));
      database.cancelError = StateError('busy');
      await expectLater(dataSource.dispose(), throwsStateError);
      await ended;
      database.cancelError = null;
    });
  });
}
