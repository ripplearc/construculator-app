import 'package:async/async.dart';
import 'package:construculator/features/calculator/data/data_source/powersync_local_group_order_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/group_order_repository_impl.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late PowerSyncLocalGroupOrderDataSource dataSource;
  late FakeClockImpl clock;
  late GroupOrderRepositoryImpl repository;
  const defaults = ['Basic Geometry', 'Shapes', 'Materials', 'Unit', 'Trig'];
  const unitFirst = ['Unit', 'Basic Geometry', 'Shapes', 'Materials', 'Trig'];

  Matcher isLeft(CalculatorErrorType errorType) =>
      predicate<Either<Failure, Object?>>(
        (result) => result.fold(
          (f) => f == CalculatorFailure(errorType: errorType),
          (_) => false,
        ),
        'Left(CalculatorFailure($errorType))',
      );

  setUp(() {
    database = FakeTradeStoresDatabase();
    dataSource = PowerSyncLocalGroupOrderDataSource(database: database);
    clock = FakeClockImpl(DateTime.utc(2026, 11, 25, 9));
    repository = GroupOrderRepositoryImpl(
      dataSource: dataSource,
      clock: clock,
      defaultOrder: defaults,
    );
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('GroupOrderRepositoryImpl', () {
    test('shows the default order until one is saved, then the saved one, '
        'and the order set is the order shown after a restart', () async {
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(repository.watchGroupOrder());
      expect(await events.next, defaults);
      expect(
        await repository.saveGroupOrder(unitFirst),
        isA<Right<Object?, Object?>>(),
      );
      expect(await events.next, unitFirst);
      await events.cancel();

      // a restart: a new data source and repository over the same database
      final restarted = GroupOrderRepositoryImpl(
        dataSource: PowerSyncLocalGroupOrderDataSource(database: database),
        clock: clock,
        defaultOrder: defaults,
      );
      expect(await restarted.watchGroupOrder().first, unitFirst);
      restarted.dispose();
      expect(
        database.tables['calculator_group_order']!.single['updated_at'],
        '2026-11-25T09:00:00.000Z',
      );
    });

    test('a stored order that does not name this build\'s groups once each '
        'shows the default: a missing group, an extra one, a repeat, an '
        'unknown id', () async {
      for (final stale in [
        ['Unit', 'Shapes', 'Materials', 'Trig'],
        ['Unit', 'Basic Geometry', 'Shapes', 'Materials', 'Trig', 'More'],
        ['Unit', 'Unit', 'Shapes', 'Materials', 'Trig'],
        ['Unit', 'Basic Geometry', 'Shapes', 'Materials', 'Trigonometry'],
      ]) {
        await dataSource.replaceGroupOrder(stale, clock.now());
        expect(
          await repository.watchGroupOrder().first,
          defaults,
          reason: '$stale',
        );
      }
      await dataSource.replaceGroupOrder(unitFirst, clock.now());
      expect(await repository.watchGroupOrder().first, unitFirst);
    });

    test('an empty stored order shows the default', () async {
      await dataSource.replaceGroupOrder(const [], clock.now());
      expect(await repository.watchGroupOrder().first, defaults);
    });

    test('an error the store raises on the watch that is not an unreadable '
        'row is passed through, not turned into the default', () async {
      final order = repository.watchGroupOrder();
      final saw = expectLater(
        order,
        emitsInOrder([defaults, emitsError(isA<StateError>())]),
      );
      await expectLater(order, emits(defaults));
      database.readError = StateError('locked');
      await database.execute(
        'INSERT INTO calculator_group_order (id, group_order, updated_at) '
        'VALUES (?, ?, ?)',
        ['group_order', '["Unit"]', '2026-11-25T09:00:00.000Z'],
      );
      await saw;
      database.readError = null;
    });

    test('the same order saved twice is shown once; the watch\'s next order '
        'is the next different one', () async {
      const trigFirst = [
        'Trig',
        'Unit',
        'Basic Geometry',
        'Shapes',
        'Materials',
      ];
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(repository.watchGroupOrder());
      expect(await events.next, defaults);
      await repository.saveGroupOrder(unitFirst);
      expect(await events.next, unitFirst);
      await repository.saveGroupOrder(unitFirst);
      await repository.saveGroupOrder(trigFirst);
      expect(await events.next, trigFirst);
      await events.cancel();
    });

    test('a row this build cannot read shows the default and keeps the '
        'watch alive', () async {
      await dataSource.replaceGroupOrder(unitFirst, clock.now());
      database.tables['calculator_group_order']!.single['group_order'] = '[1]';
      expect(await repository.watchGroupOrder().first, defaults);
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(repository.watchGroupOrder());
      expect(await events.next, defaults);
      await dataSource.replaceGroupOrder(unitFirst, clock.now());
      expect(await events.next, unitFirst, reason: 'the watch stays alive');
      await events.cancel();
    });

    test('a save the store refuses is a storage failure', () async {
      database.writeError = StateError('full');
      expect(
        await repository.saveGroupOrder(unitFirst),
        isLeft(CalculatorErrorType.storageError),
      );
    });

    test('dispose ends the watches handed out', () async {
      final order = repository.watchGroupOrder();
      final ended = expectLater(order, emitsInOrder([defaults, emitsDone]));
      await expectLater(order, emits(defaults));
      repository.dispose();
      await ended;
    });

    test('dispose returns when the store refuses to let a watch go, and the '
        'watch still ends', () async {
      final order = repository.watchGroupOrder();
      final ended = expectLater(order, emitsInOrder([defaults, emitsDone]));
      await expectLater(order, emits(defaults));
      database.cancelError = StateError('busy');
      expect(repository.dispose, returnsNormally);
      await ended;
      database.cancelError = null;
    });

    test('dispose twice does not throw', () async {
      final order = repository.watchGroupOrder();
      final ended = expectLater(order, emitsInOrder([defaults, emitsDone]));
      await expectLater(order, emits(defaults));
      expect(repository.dispose, returnsNormally);
      expect(repository.dispose, returnsNormally);
      await ended;
    });
  });
}
