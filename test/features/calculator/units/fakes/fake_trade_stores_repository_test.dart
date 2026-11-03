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
    width: Length(50 * inch, unit: Unit.inch),
    height: Length(100 * inch, unit: Unit.inch),
    position: 0,
  );
  const spacing = StoredSpacing(
    spacing: Length(12 * inch, unit: Unit.inch),
    position: 0,
  );
  const slag = StoredDensity(
    name: 'slag',
    poundsPerCubicYard: 2900,
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
    test(
      'shows Appendix B from the start, as the real repository does',
      () async {
        expect(
          await repository
              .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
              .first,
          TradeStoreSeeds.sizes(SizeStore.sheet, MeasurementSystem.imperial),
        );
        expect(
          await repository
              .watchSizes(SizeStore.sheet, MeasurementSystem.metric)
              .first,
          TradeStoreSeeds.sizes(SizeStore.sheet, MeasurementSystem.metric),
        );
        expect(
          await repository
              .watchSizes(SizeStore.masonry, MeasurementSystem.metric)
              .first,
          TradeStoreSeeds.sizes(SizeStore.masonry, MeasurementSystem.imperial),
        );
        expect(
          await repository.watchSpacings().first,
          TradeStoreSeeds.spacings,
        );
        expect(await repository.watchFence().first, TradeStoreSeeds.fence);
        expect(await repository.watchWaste().first, TradeStoreSeeds.waste);
        expect(
          await repository.watchDensities().first,
          TradeStoreSeeds.densities,
        );
      },
    );

    test('adds after the last, under both systems, with minted ids', () async {
      final expectation = expectLater(
        repository
            .watchSizes(SizeStore.sheet, MeasurementSystem.metric)
            .map((sizes) => sizes.length),
        emitsInOrder([3, 4, 5]),
      );
      final first = right(await repository.addSize(sheet));
      final second = right(await repository.addSize(sheet));
      expect(first.id, isNot(second.id));
      expect([first.position, second.position], [3, 4]);
      expect(
        (await repository
                .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
                .first)
            .skip(3),
        [first, second],
      );
      await expectation;
    });

    test(
      'a default is changed or deleted by its seed, a stored row by its id',
      () async {
        final block = TradeStoreSeeds.sizes(
          SizeStore.masonry,
          MeasurementSystem.imperial,
        ).first;
        final changed = right(
          await repository.updateSize(
            block.copyWith(width: const Length(6 * inch, unit: Unit.inch)),
          ),
        );
        expect(changed.id, isNotNull);
        expect(changed.seed, block.seed);
        expect(
          (await repository
                  .watchSizes(SizeStore.masonry, MeasurementSystem.imperial)
                  .first)
              .first,
          changed,
        );
        expect(
          await repository.updateSize(changed.copyWith(position: 5)),
          isRight(changed.copyWith(position: 5)),
        );
        expect(await repository.deleteSize(changed), isRight(null));
        expect(
          await repository
              .watchSizes(SizeStore.masonry, MeasurementSystem.imperial)
              .first,
          [
            TradeStoreSeeds.sizes(
              SizeStore.masonry,
              MeasurementSystem.imperial,
            ).last,
          ],
        );
        expect(await repository.updateSize(sheet), notFound);
        expect(
          await repository.deleteSize(sheet.copyWith(id: 'nope')),
          notFound,
        );
      },
    );

    test('spacings and densities round-trip', () async {
      final oc = right(await repository.addSpacing(spacing));
      expect(oc.position, 2);
      expect(
        await repository.updateSpacing(oc.copyWith(position: 0)),
        isRight(oc.copyWith(position: 0)),
      );
      expect(
        await repository.deleteSpacing(TradeStoreSeeds.spacings.first),
        isRight(null),
      );
      expect((await repository.watchSpacings().first).map((s) => s.seed), [
        null,
        'spacing_24in',
      ]);
      expect(await repository.updateSpacing(spacing), notFound);
      final d = right(await repository.addDensity(slag));
      expect(d.position, 3);
      final gravel = right(
        await repository.updateDensity(
          TradeStoreSeeds.densities[1].copyWith(poundsPerCubicYard: 3100),
        ),
      );
      expect(gravel.id, isNotNull);
      expect(await repository.deleteDensity(d), isRight(null));
      expect(
        (await repository.watchDensities().first).map(
          (d) => d.poundsPerCubicYard,
        ),
        [4050, 3100, 2700],
      );
      expect(await repository.deleteDensity(slag), notFound);
    });

    test('the fence and a waste factor rewrite in place', () async {
      final fence = TradeStoreSeeds.fence.copyWith(railsPerSection: 2);
      expect(await repository.updateFence(fence), isRight(fence));
      expect(await repository.watchFence().first, fence);
      const waste = StoredWaste(unit: RateUnit.sheet, percent: 5);
      expect(await repository.updateWaste(waste), isRight(waste));
      final shown = await repository.watchWaste().first;
      expect(shown.map((w) => w.unit), RateUnit.values);
      expect(shown.where((w) => w.percent != 0), [waste]);
    });

    test(
      'a configured failure or a signed-out user is answered and nothing changes',
      () async {
        repository.writeFailure = const CalculatorFailure(
          errorType: CalculatorErrorType.storageError,
        );
        expect(
          await repository.addSize(sheet),
          isLeft(CalculatorErrorType.storageError),
        );
        repository.writeFailure = null;
        repository.signedIn = false;
        expect(
          await repository.addDensity(slag),
          isLeft(CalculatorErrorType.notSignedIn),
        );
        expect(repository.sizes, hasLength(10));
        expect(repository.densities, hasLength(3));
      },
    );

    test(
      'reset puts every store back to Appendix B and clears the failure',
      () async {
        await repository.addSize(sheet);
        await repository.updateFence(
          TradeStoreSeeds.fence.copyWith(railsPerSection: 1),
        );
        await repository.updateWaste(
          const StoredWaste(unit: RateUnit.sheet, percent: 5),
        );
        repository.writeFailure = const CalculatorFailure(
          errorType: CalculatorErrorType.storageError,
        );
        repository.signedIn = false;
        repository.reset();
        expect(repository.sizes, hasLength(10));
        expect(repository.fence, TradeStoreSeeds.fence);
        expect(repository.waste, TradeStoreSeeds.waste);
        expect(repository.writeFailure, isNull);
        expect(repository.signedIn, isTrue);
      },
    );

    test(
      'a deleted entry stays hidden and comes back when changed again, as the '
      'real one\'s soft-deleted row does',
      () async {
        final blocks = TradeStoreSeeds.sizes(
          SizeStore.masonry,
          MeasurementSystem.imperial,
        );
        expect(await repository.deleteSize(blocks.first), isRight(null));
        expect(
          await repository
              .watchSizes(SizeStore.masonry, MeasurementSystem.imperial)
              .first,
          [blocks.last],
        );
        final back = right(
          await repository.updateSize(
            blocks.first.copyWith(
              width: const Length(6 * inch, unit: Unit.inch),
            ),
          ),
        );
        expect(back.id, isNotNull);
        expect(
          await repository
              .watchSizes(SizeStore.masonry, MeasurementSystem.imperial)
              .first,
          [back, blocks.last],
        );
        final added = right(await repository.addDensity(slag));
        expect(await repository.deleteDensity(added), isRight(null));
        expect(
          (await repository.watchDensities().first).map((d) => d.name),
          isNot(contains('slag')),
        );
        expect(right(await repository.addDensity(slag)).position, 3);
        expect(await repository.updateDensity(added), isRight(added));
        expect((await repository.watchDensities().first).map((d) => d.name), [
          'concrete',
          'gravel',
          'sand',
          'slag',
          'slag',
        ]);
      },
    );

    test('signed out, a watch shows Appendix B alone and ends', () async {
      await repository.addSize(sheet);
      await repository.updateFence(
        TradeStoreSeeds.fence.copyWith(railsPerSection: 1),
      );
      repository.signedIn = false;
      expect(
        await repository
            .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
            .toList(),
        [TradeStoreSeeds.sizes(SizeStore.sheet, MeasurementSystem.imperial)],
      );
      expect(await repository.watchSpacings().toList(), [
        TradeStoreSeeds.spacings,
      ]);
      expect(await repository.watchFence().toList(), [TradeStoreSeeds.fence]);
      expect(await repository.watchWaste().toList(), [TradeStoreSeeds.waste]);
      expect(await repository.watchDensities().toList(), [
        TradeStoreSeeds.densities,
      ]);
    });

    test('dispose ends its streams', () async {
      final ended = expectLater(
        repository.watchSpacings(),
        emitsInOrder([hasLength(2), emitsDone]),
      );
      repository.dispose();
      await ended;
    });
  });
}
