import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late PowerSyncLocalTradeStoresDataSource dataSource;

  const inch = Length.ticksPerInch;
  const sheet = StoredSize(
    store: SizeStore.sheet,
    system: MeasurementSystem.imperial,
    width: Length(48 * inch, unit: Unit.inch),
    height: Length(96 * inch, unit: Unit.inch),
    position: 0,
  );
  const spacing = StoredSpacing(
    spacing: Length(16 * inch, unit: Unit.inch),
    position: 0,
  );
  const fence = FenceConfiguration(
    onCentre: Length(8 * Length.ticksPerFoot, unit: Unit.foot),
    railsPerSection: 3,
  );
  const rate = StoredRate(unit: RateUnit.squareFoot, rate: 12.3);
  const concrete = StoredDensity(
    name: 'concrete',
    poundsPerCubicYard: 4050,
    position: 0,
  );

  setUp(() {
    database = FakeTradeStoresDatabase();
    // The subject under test; resolving it through Modular would test the
    // module binding instead.
    // ignore: no_direct_instantiation
    dataSource = PowerSyncLocalTradeStoresDataSource(database: database);
  });

  tearDown(() async {
    await dataSource.dispose();
    await database.closeChanges();
  });

  group('PowerSyncLocalTradeStoresDataSource', () {
    group('sizes', () {
      test(
        'inserts with a fresh id and reads back in position order',
        () async {
          final second = await dataSource.insertSize(
            sheet.copyWith(position: 1),
          );
          final first = await dataSource.insertSize(sheet);
          expect(first.id, isNotNull);
          expect(first.id, isNot(second.id));
          expect(
            await dataSource.fetchSizes(
              SizeStore.sheet,
              MeasurementSystem.imperial,
            ),
            [first, second],
          );
        },
      );

      test('reads only the store and system asked for', () async {
        await dataSource.insertSize(sheet);
        await dataSource.insertSize(sheet.copyWith(store: SizeStore.masonry));
        await dataSource.insertSize(
          sheet.copyWith(system: MeasurementSystem.metric),
        );
        final sizes = await dataSource.fetchSizes(
          SizeStore.sheet,
          MeasurementSystem.imperial,
        );
        expect(sizes, hasLength(1));
        expect(sizes.single.store, SizeStore.sheet);
        expect(sizes.single.system, MeasurementSystem.imperial);
      });

      test(
        'updates the row with the id and answers false for a stranger',
        () async {
          final stored = await dataSource.insertSize(sheet);
          final wider = stored.copyWith(
            width: const Length(50 * inch, unit: Unit.inch),
          );
          expect(await dataSource.updateSize(wider), isTrue);
          expect(
            await dataSource.fetchSizes(
              SizeStore.sheet,
              MeasurementSystem.imperial,
            ),
            [wider],
          );
          expect(
            await dataSource.updateSize(wider.copyWith(id: 'nope')),
            isFalse,
          );
          expect(await dataSource.updateSize(sheet), isFalse);
        },
      );

      test(
        'deletes the row with the id and answers false for a stranger',
        () async {
          final stored = await dataSource.insertSize(sheet);
          expect(await dataSource.deleteSize('nope'), isFalse);
          expect(await dataSource.deleteSize(stored.id!), isTrue);
          expect(
            await dataSource.fetchSizes(
              SizeStore.sheet,
              MeasurementSystem.imperial,
            ),
            isEmpty,
          );
        },
      );

      test('a watch emits now and after every change to the table', () async {
        final seen = <List<StoredSize>>[];
        final subscription = dataSource
            .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
            .listen(seen.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();
        final stored = await dataSource.insertSize(sheet);
        await dataSource.insertSpacing(spacing);
        await dataSource.deleteSize(stored.id!);
        await pumpEventQueue();
        expect(seen, [
          <StoredSize>[],
          [stored],
          <StoredSize>[],
        ]);
      });
    });

    group('spacings', () {
      test('round-trips insert, update, delete', () async {
        final stored = await dataSource.insertSpacing(spacing);
        expect(await dataSource.fetchSpacings(), [stored]);
        final wider = stored.copyWith(
          spacing: const Length(24 * inch, unit: Unit.inch),
        );
        expect(await dataSource.updateSpacing(wider), isTrue);
        expect(await dataSource.fetchSpacings(), [wider]);
        expect(await dataSource.updateSpacing(spacing), isFalse);
        expect(await dataSource.deleteSpacing(stored.id!), isTrue);
        expect(await dataSource.deleteSpacing(stored.id!), isFalse);
      });

      test(
        'a watch re-emits a changed row and collapses an unchanged one',
        () async {
          final seen = <List<StoredSpacing>>[];
          final subscription = dataSource.watchSpacings().listen(seen.add);
          addTearDown(subscription.cancel);
          await pumpEventQueue();
          final stored = await dataSource.insertSpacing(spacing);
          final wider = stored.copyWith(
            spacing: const Length(24 * inch, unit: Unit.inch),
          );
          await dataSource.updateSpacing(wider);
          await dataSource.updateSpacing(wider);
          await pumpEventQueue();
          expect(seen, [
            <StoredSpacing>[],
            [stored],
            [wider],
          ]);
        },
      );

      test('a watch follows the table', () async {
        final seen = <List<StoredSpacing>>[];
        final subscription = dataSource.watchSpacings().listen(seen.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();
        final stored = await dataSource.insertSpacing(spacing);
        await pumpEventQueue();
        expect(seen.last, [stored]);
      });
    });

    group('fence', () {
      test(
        'is null until written, then one row that upserts in place',
        () async {
          expect(await dataSource.fetchFence(), isNull);
          await dataSource.upsertFence(fence);
          expect(await dataSource.fetchFence(), fence);
          await dataSource.upsertFence(fence.copyWith(railsPerSection: 2));
          expect(
            await dataSource.fetchFence(),
            fence.copyWith(railsPerSection: 2),
          );
          expect(database.tables['calculator_fence'], hasLength(1));
        },
      );

      test('a watch follows the row', () async {
        final seen = <FenceConfiguration?>[];
        final subscription = dataSource.watchFence().listen(seen.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();
        await dataSource.upsertFence(fence);
        await pumpEventQueue();
        expect(seen, [null, fence]);
      });
    });

    group('rates', () {
      test('upserts one row per unit', () async {
        await dataSource.upsertRate(rate);
        await dataSource.upsertRate(
          const StoredRate(unit: RateUnit.sheet, rate: 14.5),
        );
        await dataSource.upsertRate(rate.copyWith(wastePercent: 10));
        final rates = await dataSource.fetchRates();
        expect(rates, hasLength(2));
        expect(rates, contains(rate.copyWith(wastePercent: 10)));
      });

      test('a watch follows the table', () async {
        final seen = <List<StoredRate>>[];
        final subscription = dataSource.watchRates().listen(seen.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();
        await dataSource.upsertRate(rate);
        await pumpEventQueue();
        expect(seen.last, [rate]);
      });
    });

    group('densities', () {
      test('round-trips insert, update, delete', () async {
        final stored = await dataSource.insertDensity(concrete);
        expect(await dataSource.fetchDensities(), [stored]);
        final heavier = stored.copyWith(poundsPerCubicYard: 4100);
        expect(await dataSource.updateDensity(heavier), isTrue);
        expect(await dataSource.fetchDensities(), [heavier]);
        expect(await dataSource.updateDensity(concrete), isFalse);
        expect(await dataSource.deleteDensity(stored.id!), isTrue);
        expect(await dataSource.deleteDensity(stored.id!), isFalse);
      });

      test('a watch follows the table', () async {
        final seen = <List<StoredDensity>>[];
        final subscription = dataSource.watchDensities().listen(seen.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();
        final stored = await dataSource.insertDensity(concrete);
        await pumpEventQueue();
        expect(seen.last, [stored]);
      });
    });

    group('errors and lifecycle', () {
      test('a failing read throws through fetch and watch', () async {
        database.readError = StateError('locked');
        expect(dataSource.fetchRates(), throwsStateError);
        expect(dataSource.watchRates().first, throwsStateError);
      });

      test(
        'dispose ends the watches handed out and leaves the database usable',
        () async {
          var done = false;
          dataSource.watchSpacings().listen((_) {}, onDone: () => done = true);
          await pumpEventQueue();
          await dataSource.dispose();
          await pumpEventQueue();
          expect(done, isTrue);
          expect(await dataSource.fetchSpacings(), isEmpty);
        },
      );

      test('a watch taken after dispose answers once and ends', () async {
        await dataSource.dispose();
        expect(await dataSource.watchDensities().toList(), [<StoredDensity>[]]);
      });
    });
  });
}
