import 'package:async/async.dart';
import 'package:construculator/features/calculator/data/data_source/powersync_local_group_order_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late PowerSyncLocalGroupOrderDataSource dataSource;
  final set = DateTime.utc(2026, 11, 25, 9);
  const basicFirst = ['Basic Geometry', 'Shapes', 'Materials', 'Unit', 'Trig'];
  const unitFirst = ['Unit', 'Basic Geometry', 'Shapes', 'Materials', 'Trig'];

  setUp(() {
    database = FakeTradeStoresDatabase();
    dataSource = PowerSyncLocalGroupOrderDataSource(database: database);
  });

  tearDown(() async {
    await dataSource.dispose();
    await database.closeChanges();
  });

  group('PowerSyncLocalGroupOrderDataSource', () {
    test('no order is null until one is set', () async {
      expect(await dataSource.fetchGroupOrder(), isNull);
      expect(await dataSource.watchGroupOrder().first, isNull);
    });

    test('an order is kept in one row, rewritten in place, and reads back '
        'in order with when it was set', () async {
      await dataSource.replaceGroupOrder(basicFirst, set);
      expect(await dataSource.fetchGroupOrder(), basicFirst);
      await dataSource.replaceGroupOrder(
        unitFirst,
        set.add(const Duration(minutes: 1)),
      );
      expect(await dataSource.fetchGroupOrder(), unitFirst);
      final rows = database.tables['calculator_group_order']!;
      expect(rows, hasLength(1));
      expect(rows.single['id'], 'group_order');
      expect(
        rows.single['group_order'],
        '["Unit","Basic Geometry","Shapes","Materials","Trig"]',
      );
      expect(rows.single['updated_at'], '2026-11-25T09:01:00.000Z');
    });

    test('a watch emits the order now and after each change, and not for '
        'the same order written again', () async {
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(dataSource.watchGroupOrder());
      expect(await events.next, isNull);
      await dataSource.replaceGroupOrder(basicFirst, set);
      expect(await events.next, basicFirst);
      await dataSource.replaceGroupOrder(basicFirst, set);
      await dataSource.replaceGroupOrder(unitFirst, set);
      expect(await events.next, unitFirst);
      await events.cancel();
    });

    test('a row whose list cannot be read is a format error', () async {
      await dataSource.replaceGroupOrder(basicFirst, set);
      final row = database.tables['calculator_group_order']!.single;
      for (final bad in <Object?>[
        'not json',
        '{"a":1}',
        '[1,2]',
        '"Unit"',
        7,
        null,
      ]) {
        row['group_order'] = bad;
        await expectLater(
          dataSource.fetchGroupOrder(),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('a row that becomes unreadable while a watch is open reaches the '
        'watch as a format error, and the watch stays open for the next '
        'order', () async {
      await dataSource.replaceGroupOrder(basicFirst, set);
      final order = dataSource.watchGroupOrder();
      final saw = expectLater(
        order,
        emitsInOrder([
          basicFirst,
          emitsError(isA<FormatException>()),
          unitFirst,
        ]),
      );
      await expectLater(order, emits(basicFirst));
      await database.execute(
        'UPDATE calculator_group_order SET group_order = ? WHERE id = ?',
        ['not json', 'group_order'],
      );
      await dataSource.replaceGroupOrder(unitFirst, set);
      await saw;
    });

    test('an empty order written reads back as an empty list, not as no '
        'order', () async {
      await dataSource.replaceGroupOrder(const [], set);
      final fetched = await dataSource.fetchGroupOrder();
      expect(fetched, isNotNull);
      expect(fetched, isEmpty);
      final watched = await dataSource.watchGroupOrder().first;
      expect(watched, isNotNull);
      expect(watched, isEmpty);
    });

    test('an order naming a group twice, four groups or six groups is kept '
        'and read back verbatim; naming every group once is the '
        'repository\'s check, not the store\'s', () async {
      for (final order in const [
        ['Unit', 'Unit', 'Shapes', 'Materials', 'Trig'],
        ['Unit', 'Shapes', 'Materials', 'Trig'],
        ['Unit', 'Basic Geometry', 'Shapes', 'Materials', 'Trig', 'More'],
      ]) {
        await dataSource.replaceGroupOrder(order, set);
        expect(await dataSource.fetchGroupOrder(), order, reason: '$order');
        expect(
          database.tables['calculator_group_order']!,
          hasLength(1),
          reason: '$order',
        );
      }
    });

    test(
      'a read or a write the store refuses is thrown to the caller',
      () async {
        database.readError = StateError('locked');
        await expectLater(dataSource.fetchGroupOrder(), throwsStateError);
        database.readError = null;
        database.writeError = StateError('full');
        await expectLater(
          dataSource.replaceGroupOrder(basicFirst, set),
          throwsStateError,
        );
      },
    );

    test('a read the store refuses while a watch is open reaches the watch '
        'as that error, and the watch stays open for the next order', () async {
      final order = dataSource.watchGroupOrder();
      final saw = expectLater(
        order,
        emitsInOrder([null, emitsError(isA<StateError>()), basicFirst]),
      );
      await expectLater(order, emits(null));
      database.readError = StateError('locked');
      await database.execute(
        'INSERT INTO calculator_group_order (id, group_order, updated_at) '
        'VALUES (?, ?, ?)',
        ['group_order', '["Unit"]', '2026-11-25T09:00:00.000Z'],
      );
      database.readError = null;
      await dataSource.replaceGroupOrder(basicFirst, set);
      await saw;
    });

    test(
      'a time set on a phone\'s clock is stored as UTC, ending in Z',
      () async {
        final local = DateTime(2026, 11, 25, 9);
        await dataSource.replaceGroupOrder(basicFirst, local);
        final stored =
            database.tables['calculator_group_order']!.single['updated_at'];
        expect(stored, local.toUtc().toIso8601String());
        expect(stored, endsWith('Z'));
      },
    );

    test('dispose twice does not throw, and the watches end once', () async {
      final order = dataSource.watchGroupOrder();
      final ended = expectLater(order, emitsInOrder([null, emitsDone]));
      await expectLater(order, emits(null));
      await expectLater(dataSource.dispose(), completes);
      await expectLater(dataSource.dispose(), completes);
      await ended;
    });

    test('dispose ends the watches handed out and leaves the store usable; '
        'a watch asked for afterwards answers once and ends', () async {
      final order = dataSource.watchGroupOrder();
      final ended = expectLater(order, emitsInOrder([null, emitsDone]));
      await expectLater(order, emits(null));
      await dataSource.dispose();
      await ended;
      await dataSource.replaceGroupOrder(basicFirst, set);
      expect(await dataSource.watchGroupOrder().toList(), [basicFirst]);
    });

    test('dispose closes a watch even when the store refuses to let it go, '
        'and throws the refusal', () async {
      final order = dataSource.watchGroupOrder();
      final ended = expectLater(order, emitsInOrder([null, emitsDone]));
      await expectLater(order, emits(null));
      database.cancelError = StateError('busy');
      await expectLater(dataSource.dispose(), throwsStateError);
      await ended;
      database.cancelError = null;
    });
  });
}
