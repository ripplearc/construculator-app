import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/calculator_store_row_dto.dart';
import 'package:construculator/features/calculator/data/models/trade_store_row_mapper.dart';
import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late FakeSupabaseWrapper supabase;
  late FakeClockImpl clock;
  late PowerSyncLocalTradeStoresDataSource dataSource;
  late TradeStoresRepositoryImpl repository;

  const inch = Length.ticksPerInch;
  const formatter = QuantityFormatter();
  const metricFormatter = QuantityFormatter(
    preferences: CalculatorPreferences(system: MeasurementSystem.metric),
  );
  const user = 'user-1';

  List<String> render(
    Iterable<StoredSize> sizes, [
    QuantityFormatter f = formatter,
  ]) => [
    for (final size in sizes)
      '${f.formatStoredLength(size.width)} x '
          '${f.formatStoredLength(size.height)}',
  ];

  StoredSize inches(SizeStore store, int width, int height) => StoredSize(
    store: store,
    width: Length(width * inch, unit: Unit.inch),
    height: Length(height * inch, unit: Unit.inch),
    position: 0,
  );

  Future<List<StoredSize>> shownSizes(
    SizeStore store,
    MeasurementSystem system,
  ) => repository.watchSizes(store, system).first;

  List<Map<String, Object?>> rows() =>
      database.tables['user_calculator_stores'] ?? const [];

  T right<T>(Either<Failure, T> result) => result.fold(
    (failure) => throw StateError('expected a value, got $failure'),
    (value) => value,
  );

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

  setUp(() {
    database = FakeTradeStoresDatabase();
    clock = FakeClockImpl(DateTime.utc(2026, 11, 2, 10));
    supabase = FakeSupabaseWrapper(clock: clock)..setInternalUserId(user);
    // The subject under test with its real data source; only the database,
    // the JWT and the clock are faked, and resolving through Modular would
    // test the binding.
    // ignore: no_direct_instantiation
    dataSource = PowerSyncLocalTradeStoresDataSource(database: database);
    // ignore: no_direct_instantiation
    repository = TradeStoresRepositoryImpl(
      dataSource: dataSource,
      supabaseWrapper: supabase,
      clock: clock,
    );
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('TradeStoresRepositoryImpl', () {
    group('sizes', () {
      test(
        'shows Appendix B for a user with no rows, per unit system',
        () async {
          final imperial = await shownSizes(
            SizeStore.sheet,
            MeasurementSystem.imperial,
          );
          expect(render(imperial), [
            '48in x 96in',
            '48in x 108in',
            '48in x 120in',
          ]);
          expect(imperial.map((s) => s.id), everyElement(isNull));
          expect(imperial.map((s) => s.position), [0, 1, 2]);
          final metric = await shownSizes(
            SizeStore.sheet,
            MeasurementSystem.metric,
          );
          expect(render(metric, metricFormatter), [
            '1200mm x 2400mm',
            '1200mm x 2700mm',
            '1200mm x 3000mm',
          ]);
          expect(
            await shownSizes(SizeStore.masonry, MeasurementSystem.metric),
            await shownSizes(SizeStore.masonry, MeasurementSystem.imperial),
          );
          expect(rows(), isEmpty);
        },
      );

      test('a size the user adds comes after the last and shows under both '
          'systems', () async {
        final stored = right(
          await repository.addSize(inches(SizeStore.sheet, 50, 100)),
        );
        expect(stored.id, isNotNull);
        expect(stored.position, 3);
        expect(stored.seed, isNull);
        final imperial = await shownSizes(
          SizeStore.sheet,
          MeasurementSystem.imperial,
        );
        expect(render(imperial).last, '50in x 100in');
        expect(imperial, hasLength(4));
        final metric = await shownSizes(
          SizeStore.sheet,
          MeasurementSystem.metric,
        );
        expect(metric, hasLength(4));
        expect(metric.last, stored);
        final next = right(
          await repository.addSize(inches(SizeStore.sheet, 60, 120)),
        );
        expect(next.position, 4);
      });

      test(
        'changing a default stores it in its place with its position',
        () async {
          final seeds = TradeStoreSeeds.sizes(
            SizeStore.sheet,
            MeasurementSystem.imperial,
          );
          final wider = seeds[1].copyWith(
            width: const Length(49 * inch, unit: Unit.inch),
          );
          final stored = right(await repository.updateSize(wider));
          expect(stored.id, isNotNull);
          expect(stored.seed, seeds[1].seed);
          expect(stored.position, 1);
          final shown = await shownSizes(
            SizeStore.sheet,
            MeasurementSystem.imperial,
          );
          expect(render(shown), [
            '48in x 96in',
            '49in x 108in',
            '48in x 120in',
          ]);
          expect(shown[1], stored);
          expect(rows(), hasLength(1));
          final narrower = right(
            await repository.updateSize(
              stored.copyWith(width: const Length(47 * inch, unit: Unit.inch)),
            ),
          );
          expect(narrower.id, stored.id);
          expect(rows(), hasLength(1));
        },
      );

      test('a changed metric sheet does not show under Imperial', () async {
        final metricSeeds = TradeStoreSeeds.sizes(
          SizeStore.sheet,
          MeasurementSystem.metric,
        );
        await repository.updateSize(
          metricSeeds.first.copyWith(
            width: const Length(2520, unit: Unit.millimetre),
          ),
        );
        final imperial = await shownSizes(
          SizeStore.sheet,
          MeasurementSystem.imperial,
        );
        expect(render(imperial), [
          '48in x 96in',
          '48in x 108in',
          '48in x 120in',
        ]);
        final metric = await shownSizes(
          SizeStore.sheet,
          MeasurementSystem.metric,
        );
        expect(render(metric, metricFormatter).first, '1000mm x 2400mm');
      });

      test(
        'deleting a default hides it, and changing it again brings it back',
        () async {
          final block = TradeStoreSeeds.sizes(
            SizeStore.masonry,
            MeasurementSystem.imperial,
          ).first;
          expect(await repository.deleteSize(block), isRight(null));
          var shown = await shownSizes(
            SizeStore.masonry,
            MeasurementSystem.imperial,
          );
          expect(render(shown), ['4in x 8in']);
          expect(rows().single['deleted_at'], isNotNull);
          expect(
            await shownSizes(SizeStore.masonry, MeasurementSystem.metric),
            shown,
          );
          await repository.updateSize(
            block.copyWith(width: const Length(6 * inch, unit: Unit.inch)),
          );
          shown = await shownSizes(
            SizeStore.masonry,
            MeasurementSystem.imperial,
          );
          expect(render(shown), ['6in x 16in', '4in x 8in']);
          expect(rows(), hasLength(1));
        },
      );

      test(
        'update and delete by id rewrite or hide the stored row, in position '
        'order',
        () async {
          final stored = right(
            await repository.addSize(inches(SizeStore.footing, 20, 10)),
          );
          final wider = stored.copyWith(
            width: const Length(22 * inch, unit: Unit.inch),
          );
          expect(await repository.updateSize(wider), isRight(wider));
          expect(
            render(
              await shownSizes(SizeStore.footing, MeasurementSystem.imperial),
            ),
            ['16in x 8in', '24in x 18in', '22in x 10in'],
          );
          // Moved to position 0 it ties with the first default, and a
          // default keeps its place at a tie, so it comes second.
          final first = wider.copyWith(position: 0);
          expect(await repository.updateSize(first), isRight(first));
          expect(
            render(
              await shownSizes(SizeStore.footing, MeasurementSystem.imperial),
            ),
            ['16in x 8in', '22in x 10in', '24in x 18in'],
          );
          expect(await repository.deleteSize(first), isRight(null));
          expect(
            await shownSizes(SizeStore.footing, MeasurementSystem.imperial),
            hasLength(2),
          );
          expect(rows(), hasLength(1));
        },
      );

      test(
        'an entry that is neither stored nor a default is not found',
        () async {
          final stranger = inches(SizeStore.sheet, 1, 1);
          expect(await repository.updateSize(stranger), notFound);
          expect(await repository.deleteSize(stranger), notFound);
          expect(
            await repository.updateSize(stranger.copyWith(id: 'nope')),
            notFound,
          );
          expect(
            await repository.deleteSize(stranger.copyWith(id: 'nope')),
            notFound,
          );
          expect(rows(), isEmpty);
        },
      );

      test(
        'of two live rows for one default, the newest write stands',
        () async {
          final seeds = TradeStoreSeeds.sizes(
            SizeStore.sheet,
            MeasurementSystem.imperial,
          );
          CalculatorStoreRowDto rowOf(StoredSize seed, int width) =>
              TradeStoreRowMapper.sizeToRow(
                seed.copyWith(width: Length(width * inch, unit: Unit.inch)),
                userId: user,
                now: clock.now(),
              );
          final olderFirst = rowOf(seeds[0], 40);
          final olderSecond = rowOf(seeds[1], 41);
          clock.advance(const Duration(minutes: 1));
          final newerFirst = rowOf(seeds[0], 44);
          final newerSecond = rowOf(seeds[1], 45);
          await dataSource.insertRow(newerFirst);
          await dataSource.insertRow(olderFirst);
          await dataSource.insertRow(olderSecond);
          await dataSource.insertRow(newerSecond);
          final shown = await shownSizes(
            SizeStore.sheet,
            MeasurementSystem.imperial,
          );
          expect(render(shown), [
            '44in x 96in',
            '45in x 108in',
            '48in x 120in',
          ]);
        },
      );

      for (final (order, liveFirst) in [
        ('the live row read first', true),
        ('the deleted row read first', false),
      ]) {
        test('a newer delete hides a default and a newer change shows it, with '
            '$order', () async {
          final seed = TradeStoreSeeds.sizes(
            SizeStore.sheet,
            MeasurementSystem.imperial,
          )[0];
          CalculatorStoreRowDto rowOf(int width) =>
              TradeStoreRowMapper.sizeToRow(
                seed.copyWith(width: Length(width * inch, unit: Unit.inch)),
                userId: user,
                now: clock.now(),
              );
          final olderLive = rowOf(40);
          clock.advance(const Duration(minutes: 1));
          final newerDeleted = rowOf(44).copyWith(deletedAt: clock.now());
          for (final row
              in liveFirst
                  ? [olderLive, newerDeleted]
                  : [newerDeleted, olderLive]) {
            await dataSource.insertRow(row);
          }
          expect(
            render(
              await shownSizes(SizeStore.sheet, MeasurementSystem.imperial),
            ),
            ['48in x 108in', '48in x 120in'],
          );

          clock.advance(const Duration(minutes: 1));
          await dataSource.insertRow(rowOf(46));
          expect(
            render(
              await shownSizes(SizeStore.sheet, MeasurementSystem.imperial),
            ),
            ['46in x 96in', '48in x 108in', '48in x 120in'],
          );
        });
      }
    });

    group('spacings and densities', () {
      test('show Appendix B, then what the user adds after the last', () async {
        expect(
          (await repository.watchSpacings().first).map(
            (s) => formatter.format(s.spacing),
          ),
          ['16in', '24in'],
        );
        final added = right(
          await repository.addSpacing(
            const StoredSpacing(
              spacing: Length(12 * inch, unit: Unit.inch),
              position: 0,
            ),
          ),
        );
        expect(added.position, 2);
        expect((await repository.watchSpacings().first).last, added);
        expect((await repository.watchDensities().first).map((d) => d.name), [
          'concrete',
          'gravel',
          'sand',
        ]);
        final slag = right(
          await repository.addDensity(
            const StoredDensity(
              name: 'slag',
              poundsPerCubicYard: 2900,
              position: 0,
            ),
          ),
        );
        expect(slag.position, 3);
        expect((await repository.watchDensities().first).last, slag);
      });

      test(
        'a default spacing or density is changed or deleted by its seed',
        () async {
          final sixteen = TradeStoreSeeds.spacings.first;
          expect(await repository.deleteSpacing(sixteen), isRight(null));
          expect((await repository.watchSpacings().first).map((s) => s.seed), [
            'spacing_24in',
          ]);
          final wider = right(
            await repository.updateSpacing(
              TradeStoreSeeds.spacings.last.copyWith(
                spacing: const Length(32 * inch, unit: Unit.inch),
              ),
            ),
          );
          expect(wider.id, isNotNull);
          final moved = wider.copyWith(position: 5);
          expect(await repository.updateSpacing(moved), isRight(moved));
          expect(
            (await repository.watchSpacings().first).map(
              (s) => formatter.format(s.spacing),
            ),
            ['32in'],
          );
          final gravel = TradeStoreSeeds.densities[1];
          final heavier = right(
            await repository.updateDensity(
              gravel.copyWith(poundsPerCubicYard: 3100),
            ),
          );
          expect(heavier.id, isNotNull);
          expect(
            (await repository.watchDensities().first).map(
              (d) => d.poundsPerCubicYard,
            ),
            [4050, 3100, 2700],
          );
          final renamed = heavier.copyWith(name: 'Gravel');
          expect(await repository.updateDensity(renamed), isRight(renamed));
          expect(await repository.deleteDensity(renamed), isRight(null));
          expect((await repository.watchDensities().first).map((d) => d.name), [
            'concrete',
            'sand',
          ]);
        },
      );
    });

    group('fence and waste', () {
      test('the fence reads Appendix B until it is changed', () async {
        final changed = TradeStoreSeeds.fence.copyWith(railsPerSection: 2);
        final expectation = expectLater(
          repository.watchFence(),
          emitsInOrder([TradeStoreSeeds.fence, changed]),
        );
        expect(await repository.updateFence(changed), isRight(changed));
        await expectation;
        expect(rows(), hasLength(1));
        await repository.updateFence(changed.copyWith(railsPerSection: 4));
        expect(rows(), hasLength(1));
      });

      test(
        'a row that names no default, or a deleted fence row, is ignored',
        () async {
          await dataSource.insertRow(
            TradeStoreRowMapper.wasteToRow(
              const StoredWaste(unit: RateUnit.sheet, percent: 9),
              userId: user,
              now: clock.now(),
            ).copyWith(values: const {'percent': 9}),
          );
          expect(await repository.watchWaste().first, TradeStoreSeeds.waste);
          await dataSource.insertRow(
            TradeStoreRowMapper.fenceToRow(
              TradeStoreSeeds.fence.copyWith(railsPerSection: 1),
              userId: user,
              now: clock.now(),
            ).copyWith(deletedAt: clock.now()),
          );
          expect(await repository.watchFence().first, TradeStoreSeeds.fence);
        },
      );

      test(
        'every unit has a waste factor of 0% until its own is changed',
        () async {
          final before = await repository.watchWaste().first;
          expect(before.map((w) => w.unit), RateUnit.values);
          expect(before.map((w) => w.percent), everyElement(0));
          const edited = StoredWaste(unit: RateUnit.sheet, percent: 5);
          expect(await repository.updateWaste(edited), isRight(edited));
          final after = await repository.watchWaste().first;
          expect(after.map((w) => w.unit), RateUnit.values);
          expect(after.where((w) => w.percent != 0), [edited]);
        },
      );
    });

    group('signed out', () {
      setUp(() => supabase.setInternalUserId(null));

      test('a watch shows the defaults alone and ends', () async {
        expect(
          await repository
              .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
              .toList(),
          [TradeStoreSeeds.sizes(SizeStore.sheet, MeasurementSystem.imperial)],
        );
        expect(await repository.watchFence().first, TradeStoreSeeds.fence);
      });

      test('a write is refused and stores nothing', () async {
        expect(
          await repository.addSize(inches(SizeStore.sheet, 50, 100)),
          notSignedIn,
        );
        expect(
          await repository.updateFence(TradeStoreSeeds.fence),
          notSignedIn,
        );
        expect(
          await repository.deleteDensity(TradeStoreSeeds.densities.first),
          notSignedIn,
        );
        expect(rows(), isEmpty);
      });
    });

    group('errors and lifecycle', () {
      test(
        'a database that cannot be read or written is a storage failure',
        () async {
          database.readError = StateError('locked');
          expect(
            await repository.addSize(inches(SizeStore.sheet, 50, 100)),
            storageError,
          );
          await expectLater(
            repository.watchSpacings(),
            emitsError(isA<StateError>()),
          );
          database.readError = null;
          database.writeError = StateError('locked');
          expect(
            await repository.updateFence(TradeStoreSeeds.fence),
            storageError,
          );
          expect(
            await repository.deleteSpacing(TradeStoreSeeds.spacings.first),
            storageError,
          );
        },
      );

      test('watches follow the store and end on dispose', () async {
        final counts = repository.watchDensities().map((d) => d.length);
        final expectation = expectLater(
          counts,
          emitsInOrder([3, 4, emitsDone]),
        );
        await repository.addDensity(
          const StoredDensity(
            name: 'slag',
            poundsPerCubicYard: 2900,
            position: 0,
          ),
        );
        await expectLater(counts, emits(4));
        repository.dispose();
        await expectation;
      });

      test('dispose never throws and still ends the watches, even when the '
          'source fails to let go', () async {
        final densities = repository.watchDensities();
        final ended = expectLater(
          densities,
          emitsInOrder([hasLength(3), emitsDone]),
        );
        await expectLater(densities, emits(hasLength(3)));
        database.cancelError = StateError('busy');
        expect(repository.dispose, returnsNormally);
        await ended;
      });
    });
  });
}
