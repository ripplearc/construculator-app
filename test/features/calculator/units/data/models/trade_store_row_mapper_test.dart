import 'package:construculator/features/calculator/data/models/calculator_store_row_dto.dart';
import 'package:construculator/features/calculator/data/models/trade_store_row_mapper.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inch = Length.ticksPerInch;
  final now = DateTime.utc(2026, 11, 2, 10);
  const user = 'user-1';

  CalculatorStoreRowDto stored(CalculatorStoreRowDto row) =>
      row.copyWith(id: 'row-1');

  group('TradeStoreRowMapper', () {
    test('a size round-trips through its row, in the unit it was typed', () {
      const size = StoredSize(
        store: SizeStore.footing,
        width: Length(16 * inch, unit: Unit.inch),
        height: Length(8 * inch, unit: Unit.inch),
        position: 2,
        seed: 'footing_16x8in',
      );
      final row = TradeStoreRowMapper.sizeToRow(size, userId: user, now: now);
      expect(row.storeKind, CalculatorStoreKind.footingSection);
      expect(row.userId, user);
      expect(row.unitSystem, MeasurementSystem.imperial);
      expect(row.createdAt, now);
      expect(row.values, {
        'seed': 'footing_16x8in',
        'width_ticks': 16 * inch,
        'height_ticks': 8 * inch,
        'unit': 'inch',
        'position': 2,
      });
      expect(
        TradeStoreRowMapper.sizeFromRow(stored(row)),
        size.copyWith(id: 'row-1'),
      );
    });

    test('a metric size is a metric row that reads back in millimetres', () {
      const size = StoredSize(
        id: 'row-9',
        store: SizeStore.sheet,
        width: Length(3024, unit: Unit.millimetre),
        height: Length(6047, unit: Unit.millimetre),
        position: 0,
      );
      final row = TradeStoreRowMapper.sizeToRow(size, userId: user, now: now);
      expect(row.id, 'row-9');
      expect(row.unitSystem, MeasurementSystem.metric);
      expect(row.values, isNot(contains('seed')));
      expect(TradeStoreRowMapper.sizeFromRow(row), size);
      expect(TradeStoreRowMapper.sizeFromRow(row).width.unit, Unit.millimetre);
    });

    test('each size store has its kind and back', () {
      for (final store in SizeStore.values) {
        expect(
          TradeStoreRowMapper.storeOf(TradeStoreRowMapper.kindOf(store)),
          store,
        );
      }
      expect(
        TradeStoreRowMapper.kindOf(SizeStore.sheet),
        CalculatorStoreKind.sheetSize,
      );
      expect(
        TradeStoreRowMapper.kindOf(SizeStore.masonry),
        CalculatorStoreKind.masonryPiece,
      );
      for (final kind in [
        CalculatorStoreKind.onCentreSpacing,
        CalculatorStoreKind.fenceConfig,
        CalculatorStoreKind.waste,
        CalculatorStoreKind.density,
      ]) {
        expect(TradeStoreRowMapper.storeOf(kind), isNull);
      }
    });

    test('a spacing round-trips', () {
      const spacing = StoredSpacing(
        spacing: Length(24 * inch, unit: Unit.inch),
        position: 1,
        seed: 'spacing_24in',
      );
      final row = TradeStoreRowMapper.spacingToRow(
        spacing,
        userId: user,
        now: now,
      );
      expect(row.storeKind, CalculatorStoreKind.onCentreSpacing);
      expect(row.values, {
        'seed': 'spacing_24in',
        'ticks': 24 * inch,
        'unit': 'inch',
        'position': 1,
      });
      expect(
        TradeStoreRowMapper.spacingFromRow(stored(row)),
        spacing.copyWith(id: 'row-1'),
      );
    });

    test('the fence is the one row seeded fence', () {
      const fence = FenceConfiguration(
        onCentre: Length(8 * Length.ticksPerFoot, unit: Unit.foot),
        railsPerSection: 3,
      );
      final row = TradeStoreRowMapper.fenceToRow(fence, userId: user, now: now);
      expect(row.storeKind, CalculatorStoreKind.fenceConfig);
      expect(row.seed, TradeStoreRowMapper.fenceSeed);
      expect(row.values, {
        'seed': 'fence',
        'on_centre_ticks': 8 * Length.ticksPerFoot,
        'unit': 'foot',
        'rails_per_section': 3,
      });
      expect(TradeStoreRowMapper.fenceFromRow(stored(row)), fence);
    });

    test(
      'a waste factor is seeded by its unit, metric for the metre units',
      () {
        const waste = StoredWaste(unit: RateUnit.cubicMetre, percent: 7);
        final row = TradeStoreRowMapper.wasteToRow(
          waste,
          userId: user,
          now: now,
        );
        expect(row.storeKind, CalculatorStoreKind.waste);
        expect(row.seed, 'cubicMetre');
        expect(row.unitSystem, MeasurementSystem.metric);
        expect(row.values, {'seed': 'cubicMetre', 'percent': 7.0});
        expect(TradeStoreRowMapper.wasteFromRow(stored(row)), waste);
        expect(
          TradeStoreRowMapper.wasteToRow(
            const StoredWaste(unit: RateUnit.thousandBoardFeet),
            userId: user,
            now: now,
          ).unitSystem,
          MeasurementSystem.imperial,
        );
      },
    );

    test('a density round-trips and is always an imperial row', () {
      const density = StoredDensity(
        name: 'gravel',
        poundsPerCubicYard: 3000,
        position: 1,
        seed: 'density_gravel',
      );
      final row = TradeStoreRowMapper.densityToRow(
        density,
        userId: user,
        now: now,
      );
      expect(row.storeKind, CalculatorStoreKind.density);
      expect(row.unitSystem, MeasurementSystem.imperial);
      expect(row.values, {
        'seed': 'density_gravel',
        'name': 'gravel',
        'pounds_per_cubic_yard': 3000.0,
        'position': 1,
      });
      expect(
        TradeStoreRowMapper.densityFromRow(stored(row)),
        density.copyWith(id: 'row-1'),
      );
    });

    test('a real value read as an integer is widened', () {
      final row =
          TradeStoreRowMapper.densityToRow(
            const StoredDensity(
              name: 'sand',
              poundsPerCubicYard: 2700,
              position: 2,
            ),
            userId: user,
            now: now,
          ).copyWith(
            values: const {
              'name': 'sand',
              'pounds_per_cubic_yard': 2700,
              'position': 2,
            },
          );
      expect(
        TradeStoreRowMapper.densityFromRow(row).poundsPerCubicYard,
        2700.0,
      );
    });

    test('values that cannot be read are a format error', () {
      final size = TradeStoreRowMapper.sizeToRow(
        const StoredSize(
          store: SizeStore.sheet,
          width: Length(48 * inch, unit: Unit.inch),
          height: Length(96 * inch, unit: Unit.inch),
          position: 0,
        ),
        userId: user,
        now: now,
      );
      expect(
        () => TradeStoreRowMapper.sizeFromRow(
          size.copyWith(values: const {'unit': 'inch', 'position': 0}),
        ),
        throwsFormatException,
      );
      expect(
        () => TradeStoreRowMapper.sizeFromRow(
          size.copyWith(values: {...size.values, 'width_ticks': 'wide'}),
        ),
        throwsFormatException,
      );
      expect(
        () => TradeStoreRowMapper.sizeFromRow(
          size.copyWith(values: {...size.values, 'unit': 7}),
        ),
        throwsFormatException,
      );
      expect(
        () => TradeStoreRowMapper.spacingFromRow(
          size.copyWith(values: const {'ticks': 64, 'unit': 'inch'}),
        ),
        throwsFormatException,
      );
      expect(
        () => TradeStoreRowMapper.wasteFromRow(
          size.copyWith(values: const {'seed': 'sheet', 'percent': 'lots'}),
        ),
        throwsFormatException,
      );
      final waste = TradeStoreRowMapper.wasteToRow(
        const StoredWaste(unit: RateUnit.sheet),
        userId: user,
        now: now,
      );
      expect(
        () => TradeStoreRowMapper.sizeFromRow(waste),
        throwsFormatException,
      );
    });
  });
}
