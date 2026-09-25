import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';

/// The values every store starts with (UX Design Doc Appendix B, "Stored
/// defaults"), in the order the strip offers them.
///
/// Sheet sizes are seeded per unit system — 48in × 96in under Imperial,
/// 1200 × 2400 mm under Metric — where the prototype seeded metric sheets
/// in inches (47.24in × 94.49in); Appendix D records that its walkthrough
/// screens show the prototype's seeds. Masonry pieces and footing
/// cross-sections are quoted in inches by the trade in both systems. Every
/// length is whole ticks, rounded as the parser rounds a typed value, and
/// spelled in the unit the seed was quoted in.
abstract final class TradeStoreSeeds {
  /// Every seed size, for both systems.
  static List<StoredSize> get sizes => [
    ..._sizes(SizeStore.sheet, MeasurementSystem.imperial, const [
      (48, 96),
      (48, 108),
      (48, 120),
    ], Unit.inch),
    ..._sizes(SizeStore.sheet, MeasurementSystem.metric, const [
      (1200, 2400),
      (1200, 2700),
      (1200, 3000),
    ], Unit.millimetre),
    for (final system in MeasurementSystem.values) ...[
      ..._sizes(SizeStore.masonry, system, const [(8, 16), (4, 8)], Unit.inch),
      ..._sizes(SizeStore.footing, system, const [
        (16, 8),
        (24, 18),
      ], Unit.inch),
    ],
  ];

  /// The on-centre spacings: 16in, 24in.
  static List<StoredSpacing> get spacings => [
    for (final (index, inches) in const [16, 24].indexed)
      StoredSpacing(spacing: _length(inches, Unit.inch), position: index),
  ];

  /// The fence: O.C. 8ft, 3 rails per section.
  static FenceConfiguration get fence =>
      FenceConfiguration(onCentre: _length(8, Unit.foot), railsPerSection: 3);

  /// The rates per unit; waste starts at 0% everywhere.
  static const List<StoredRate> rates = [
    StoredRate(unit: RateUnit.squareFoot, rate: 12.3),
    StoredRate(unit: RateUnit.squareYard, rate: 123),
    StoredRate(unit: RateUnit.squareMetre, rate: 132),
    StoredRate(unit: RateUnit.squareInch, rate: 0.09),
    StoredRate(unit: RateUnit.cubicFoot, rate: 6.5),
    StoredRate(unit: RateUnit.cubicYard, rate: 150),
    StoredRate(unit: RateUnit.cubicMetre, rate: 196),
    StoredRate(unit: RateUnit.sheet, rate: 14.5),
    StoredRate(unit: RateUnit.thousandBoardFeet, rate: 412),
  ];

  /// The densities in lbs/yd³: concrete, gravel, sand.
  static const List<StoredDensity> densities = [
    StoredDensity(name: 'concrete', poundsPerCubicYard: 4050, position: 0),
    StoredDensity(name: 'gravel', poundsPerCubicYard: 3000, position: 1),
    StoredDensity(name: 'sand', poundsPerCubicYard: 2700, position: 2),
  ];

  static List<StoredSize> _sizes(
    SizeStore store,
    MeasurementSystem system,
    List<(int, int)> sizes,
    Unit unit,
  ) => [
    for (final (index, (width, height)) in sizes.indexed)
      StoredSize(
        store: store,
        system: system,
        width: _length(width, unit),
        height: _length(height, unit),
        position: index,
      ),
  ];

  static Length _length(int value, Unit unit) =>
      Length((value * unit.ticksPerUnit).round(), unit: unit);
}
