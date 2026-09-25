import 'dart:async';

import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';

/// A [FakePowerSyncDatabase] that applies the statements
/// [PowerSyncLocalTradeStoresDataSource] issues to in-memory rows.
///
/// Unlike the consent fake this one executes the writes, because the
/// behaviour under test is a round trip: what an insert wrote is what the
/// next read and the open watch see. The SQL shapes recognised are exactly
/// the five the data source builds; anything else is a [StateError], so a
/// changed query fails loudly rather than reading nothing.
class _FakeTradeStoresDatabase extends FakePowerSyncDatabase {
  /// Rows by table name, column names as in `schema.dart`.
  final Map<String, List<Map<String, Object?>>> tables = {};

  /// Thrown by the next read when set.
  Object? readError;

  /// Every statement executed, in order.
  final List<String> executed = [];

  final StreamController<String> _changes = StreamController.broadcast();

  /// Closes the change stream, ending any [watch] this fake handed out.
  Future<void> closeChanges() => _changes.close();

  @override
  Future<ResultSet> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async => _query(sql, parameters);

  @override
  Future<ResultSet> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    executed.add(sql);
    final insert = RegExp(
      r'^INSERT INTO (\w+) \((.+)\) VALUES',
    ).firstMatch(sql);
    if (insert != null) {
      final columns = insert.group(2)!.split(', ');
      _rows(insert.group(1)!).add({
        for (var i = 0; i < columns.length; i++) columns[i]: parameters[i],
      });
      _changes.add(insert.group(1)!);
      return _empty();
    }
    final update = RegExp(
      r'^UPDATE (\w+) SET (.+) WHERE id = \?$',
    ).firstMatch(sql);
    if (update != null) {
      final columns = update
          .group(2)!
          .split(', ')
          .map((c) => c.split(' = ').first)
          .toList();
      final row = _rows(
        update.group(1)!,
      ).firstWhere((r) => r['id'] == parameters.last);
      for (var i = 0; i < columns.length; i++) {
        row[columns[i]] = parameters[i];
      }
      _changes.add(update.group(1)!);
      return _empty();
    }
    final delete = RegExp(r'^DELETE FROM (\w+) WHERE id = \?$').firstMatch(sql);
    if (delete != null) {
      _rows(delete.group(1)!).removeWhere((r) => r['id'] == parameters.first);
      _changes.add(delete.group(1)!);
      return _empty();
    }
    throw StateError('Unexpected statement: $sql');
  }

  @override
  Stream<ResultSet> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = const Duration(milliseconds: 30),
    Iterable<String>? triggerOnTables,
  }) => Stream<ResultSet>.multi((controller) {
    void emit() {
      try {
        controller.add(_query(sql, parameters));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    final subscription = _changes.stream
        .where(
          (table) => triggerOnTables == null || triggerOnTables.contains(table),
        )
        .listen((_) => emit(), onDone: controller.close);
    controller.onCancel = subscription.cancel;
    emit();
  });

  List<Map<String, Object?>> _rows(String table) =>
      tables.putIfAbsent(table, () => []);

  ResultSet _query(String sql, List<Object?> parameters) {
    final error = readError;
    if (error != null) throw error;
    final select = RegExp(
      r'^SELECT (.+) FROM (\w+)(?: WHERE (.+?))?(?: ORDER BY position)?$',
    ).firstMatch(sql);
    if (select == null) throw StateError('Unexpected statement: $sql');
    final columns = select.group(1)!.split(', ');
    var rows = _rows(select.group(2)!).toList();
    final where = select.group(3);
    if (where != null) {
      final conditions = where
          .split(' AND ')
          .map((c) => c.split(' = ').first)
          .toList();
      rows = rows.where((row) {
        for (var i = 0; i < conditions.length; i++) {
          if (row[conditions[i]] != parameters[i]) return false;
        }
        return true;
      }).toList();
    }
    if (sql.endsWith('ORDER BY position')) {
      rows.sort(
        (a, b) => (a['position']! as int).compareTo(b['position']! as int),
      );
    }
    if (rows.isEmpty) return _empty();
    return ResultSet(columns, null, [
      for (final row in rows) [for (final column in columns) row[column]],
    ]);
  }

  ResultSet _empty() => ResultSet(const [], null, const []);
}

void main() {
  late _FakeTradeStoresDatabase database;
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
    database = _FakeTradeStoresDatabase();
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
