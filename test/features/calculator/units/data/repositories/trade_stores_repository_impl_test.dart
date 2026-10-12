import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late PowerSyncLocalTradeStoresDataSource dataSource;
  late TradeStoresRepositoryImpl repository;

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
  const concrete = StoredDensity(
    name: 'concrete',
    poundsPerCubicYard: 4050,
    position: 0,
  );

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
  final storageError = isLeft(CalculatorErrorType.storageError);

  setUp(() {
    database = FakeTradeStoresDatabase();
    // The subject under test with its real data source; only the database
    // is faked, and resolving through Modular would test the binding.
    // ignore: no_direct_instantiation
    dataSource = PowerSyncLocalTradeStoresDataSource(database: database);
    // ignore: no_direct_instantiation
    repository = TradeStoresRepositoryImpl(dataSource: dataSource);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('TradeStoresRepositoryImpl', () {
    group('seedDefaults', () {
      test(
        'fills every empty store with Appendix B and leaves a filled one',
        () async {
          final stored = right(
            await repository.addSize(sheet.copyWith(position: 9)),
          );
          expect(await repository.seedDefaults(), isRight(null));

          expect(
            await repository
                .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
                .first,
            [stored],
          );
          expect(
            await repository
                .watchSizes(SizeStore.sheet, MeasurementSystem.metric)
                .first,
            hasLength(3),
          );
          expect(
            await repository
                .watchSizes(SizeStore.masonry, MeasurementSystem.imperial)
                .first,
            hasLength(2),
          );
          expect(await repository.watchSpacings().first, hasLength(2));
          expect(await repository.watchFence().first, TradeStoreSeeds.fence);
          expect(await repository.watchRates().first, hasLength(9));
          expect((await repository.watchDensities().first).map((d) => d.name), [
            'concrete',
            'gravel',
            'sand',
          ]);
        },
      );

      test('is safe to run twice', () async {
        await repository.seedDefaults();
        await repository.seedDefaults();
        expect(await repository.watchSpacings().first, hasLength(2));
        expect(database.tables['calculator_fence'], hasLength(1));
      });

      test(
        'answers a storage failure when the database cannot be read',
        () async {
          database.readError = StateError('locked');
          expect(await repository.seedDefaults(), storageError);
        },
      );
    });

    group('writes', () {
      test('add answers the stored row with its id', () async {
        final stored = right(await repository.addSize(sheet));
        expect(stored.id, isNotNull);
        expect(right(await repository.addSpacing(spacing)).id, isNotNull);
        expect(right(await repository.addDensity(concrete)).id, isNotNull);
      });

      test('update answers the row, or not found for a stranger', () async {
        final stored = right(await repository.addSize(sheet));
        final wider = stored.copyWith(
          width: const Length(50 * inch, unit: Unit.inch),
        );
        expect(await repository.updateSize(wider), isRight(wider));
        expect(await repository.updateSize(sheet), notFound);
        final oc = right(await repository.addSpacing(spacing));
        expect(await repository.updateSpacing(oc), isRight(oc));
        expect(await repository.updateSpacing(spacing), notFound);
        final d = right(await repository.addDensity(concrete));
        expect(await repository.updateDensity(d), isRight(d));
        expect(await repository.updateDensity(concrete), notFound);
      });

      test('delete answers nothing, or not found for a stranger', () async {
        final stored = right(await repository.addSize(sheet));
        expect(await repository.deleteSize(stored.id!), isRight(null));
        expect(await repository.deleteSize(stored.id!), notFound);
        final oc = right(await repository.addSpacing(spacing));
        expect(await repository.deleteSpacing(oc.id!), isRight(null));
        expect(await repository.deleteSpacing('nope'), notFound);
        final d = right(await repository.addDensity(concrete));
        expect(await repository.deleteDensity(d.id!), isRight(null));
        expect(await repository.deleteDensity('nope'), notFound);
      });

      test('the fence and a rate are rewritten in place', () async {
        final fence = TradeStoreSeeds.fence.copyWith(railsPerSection: 2);
        expect(await repository.updateFence(fence), isRight(fence));
        expect(await repository.watchFence().first, fence);
        const rate = StoredRate(
          unit: RateUnit.sheet,
          rate: 15,
          wastePercent: 5,
        );
        expect(await repository.updateRate(rate), isRight(rate));
        expect(await repository.watchRates().first, [rate]);
      });

      test('a database error is a storage failure, never a throw', () async {
        database.readError = StateError('locked');
        expect(
          await repository.updateSize(sheet.copyWith(id: 'x')),
          storageError,
        );
        expect(await repository.deleteDensity('x'), storageError);
      });
    });

    group('watches', () {
      test('the fence reads Appendix B before it is seeded', () async {
        expect(await repository.watchFence().first, TradeStoreSeeds.fence);
      });

      test(
        'dispose logs a source that fails to close and never throws',
        () async {
          repository.watchDensities().listen((_) {});
          await pumpEventQueue();
          database.cancelError = StateError('busy');

          expect(repository.dispose, returnsNormally);
          await pumpEventQueue();
        },
      );

      test('follow the stores and end on dispose', () async {
        final seen = <List<StoredDensity>>[];
        var done = false;
        repository.watchDensities().listen(seen.add, onDone: () => done = true);
        await pumpEventQueue();
        final stored = right(await repository.addDensity(concrete));
        await pumpEventQueue();
        expect(seen.last, [stored]);
        repository.dispose();
        await pumpEventQueue();
        expect(done, isTrue);
      });
    });
  });
}
