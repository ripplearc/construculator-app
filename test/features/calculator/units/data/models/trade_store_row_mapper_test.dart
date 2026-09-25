import 'package:construculator/features/calculator/data/models/trade_store_row_mapper.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inch = Length.ticksPerInch;

  group('TradeStoreRowMapper', () {
    test('a size round-trips through its row, read back in inches', () {
      const size = StoredSize(
        id: 's-1',
        store: SizeStore.footing,
        system: MeasurementSystem.metric,
        width: Length(16 * inch, unit: Unit.inch),
        height: Length(8 * inch, unit: Unit.inch),
        position: 2,
      );
      final row = TradeStoreRowMapper.sizeToRow(size);
      expect(row, {
        'store': 'footing',
        'system': 'metric',
        'width_ticks': 16 * inch,
        'height_ticks': 8 * inch,
        'position': 2,
      });
      expect(TradeStoreRowMapper.sizeFromRow({'id': 's-1', ...row}), size);
    });

    test('a spacing, the fence, a rate and a density round-trip', () {
      const spacing = StoredSpacing(
        id: 'o-1',
        spacing: Length(24 * inch, unit: Unit.inch),
        position: 1,
      );
      expect(
        TradeStoreRowMapper.spacingFromRow({
          'id': 'o-1',
          ...TradeStoreRowMapper.spacingToRow(spacing),
        }),
        spacing,
      );
      const fence = FenceConfiguration(
        onCentre: Length(8 * Length.ticksPerFoot, unit: Unit.foot),
        railsPerSection: 3,
      );
      expect(
        TradeStoreRowMapper.fenceFromRow({
          'id': 'f',
          ...TradeStoreRowMapper.fenceToRow(fence),
        }),
        fence,
      );
      const rate = StoredRate(
        unit: RateUnit.thousandBoardFeet,
        rate: 412,
        wastePercent: 5,
      );
      expect(
        TradeStoreRowMapper.rateFromRow({
          'id': 'r',
          ...TradeStoreRowMapper.rateToRow(rate),
        }),
        rate,
      );
      const density = StoredDensity(
        id: 'd-1',
        name: 'gravel',
        poundsPerCubicYard: 3000,
        position: 1,
      );
      expect(
        TradeStoreRowMapper.densityFromRow({
          'id': 'd-1',
          ...TradeStoreRowMapper.densityToRow(density),
        }),
        density,
      );
    });

    test('a real column read as an integer is widened', () {
      final rate = TradeStoreRowMapper.rateFromRow({
        'id': 'r',
        'unit': 'sheet',
        'rate': 14,
        'waste_percent': 0,
      });
      expect(rate.rate, 14.0);
    });

    test('a column that cannot be read is a format error', () {
      expect(
        () => TradeStoreRowMapper.sizeFromRow({'id': 's', 'store': 'sheet'}),
        throwsFormatException,
      );
      expect(
        () => TradeStoreRowMapper.sizeFromRow({
          'id': 's',
          'store': 'sheet',
          'system': 'imperial',
          'width_ticks': 'wide',
          'height_ticks': 1,
          'position': 0,
        }),
        throwsFormatException,
      );
      expect(
        () => TradeStoreRowMapper.spacingFromRow({
          'id': 1,
          'ticks': 64,
          'position': 0,
        }),
        throwsFormatException,
      );
      expect(
        () => TradeStoreRowMapper.rateFromRow({
          'id': 'r',
          'unit': 'sheet',
          'rate': 'lots',
          'waste_percent': 0,
        }),
        throwsFormatException,
      );
    });
  });
}
