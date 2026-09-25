import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/testing/fake_trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeTradeStoresRepository repository;

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
    position: 1,
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

  setUp(() {
    repository = FakeTradeStoresRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  group('FakeTradeStoresRepository', () {
    test('seeds every store once and counts the calls', () async {
      await repository.seedDefaults();
      await repository.seedDefaults();
      expect(repository.seedCalls, 2);
      expect(
        await repository
            .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
            .first,
        hasLength(3),
      );
      expect(await repository.watchSpacings().first, hasLength(2));
      expect(await repository.watchDensities().first, hasLength(3));
      expect(await repository.watchFence().first, TradeStoreSeeds.fence);
      expect(await repository.watchRates().first, hasLength(9));
    });

    test(
      'adds, updates and deletes with minted ids, watched in position order',
      () async {
        final seen = <List<StoredSize>>[];
        final subscription = repository
            .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
            .listen(seen.add);
        addTearDown(subscription.cancel);
        final second = right(
          await repository.addSize(sheet.copyWith(position: 1)),
        );
        final first = right(await repository.addSize(sheet));
        expect(first.id, isNot(second.id));
        await pumpEventQueue();
        expect(seen.last, [first, second]);
        final wider = first.copyWith(
          width: const Length(50 * inch, unit: Unit.inch),
        );
        expect(await repository.updateSize(wider), isRight(wider));
        expect(await repository.updateSize(sheet), notFound);
        expect(await repository.deleteSize(first.id!), isRight(null));
        expect(await repository.deleteSize(first.id!), notFound);
      },
    );

    test('spacings and densities round-trip', () async {
      final oc = right(await repository.addSpacing(spacing));
      expect(await repository.watchSpacings().first, [oc]);
      expect(
        await repository.updateSpacing(oc.copyWith(position: 0)),
        isRight(oc.copyWith(position: 0)),
      );
      expect(await repository.updateSpacing(spacing), notFound);
      expect(await repository.deleteSpacing(oc.id!), isRight(null));
      expect(await repository.deleteSpacing('x'), notFound);
      final d = right(await repository.addDensity(concrete));
      expect(await repository.watchDensities().first, [d]);
      expect(
        await repository.updateDensity(d.copyWith(name: 'Concrete')),
        isRight(d.copyWith(name: 'Concrete')),
      );
      expect(await repository.updateDensity(concrete), notFound);
      expect(await repository.deleteDensity(d.id!), isRight(null));
      expect(await repository.deleteDensity('x'), notFound);
    });

    test('the fence and rates rewrite in place', () async {
      final fence = TradeStoreSeeds.fence.copyWith(railsPerSection: 2);
      expect(await repository.updateFence(fence), isRight(fence));
      expect(await repository.watchFence().first, fence);
      const rate = StoredRate(unit: RateUnit.sheet, rate: 15);
      expect(await repository.updateRate(rate), isRight(rate));
      expect(
        (await repository.watchRates().first).firstWhere(
          (r) => r.unit == RateUnit.sheet,
        ),
        rate,
      );
    });

    test('a configured failure is answered and nothing changes', () async {
      repository.writeFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );
      expect(
        await repository.addSize(sheet),
        isLeft(CalculatorErrorType.storageError),
      );
      expect(repository.sizes, isEmpty);
    });

    test('reset empties every store and clears the failure', () async {
      await repository.seedDefaults();
      repository.writeFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );
      repository.reset();
      expect(repository.sizes, isEmpty);
      expect(repository.spacings, isEmpty);
      expect(repository.densities, isEmpty);
      expect(repository.writeFailure, isNull);
      expect(repository.seedCalls, 0);
      expect(repository.rates, hasLength(9));
    });

    test('dispose ends its streams', () async {
      var done = false;
      repository.watchSpacings().listen((_) {}, onDone: () => done = true);
      repository.dispose();
      await pumpEventQueue();
      expect(done, isTrue);
    });
  });
}
