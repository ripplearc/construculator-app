import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';

/// The values every store starts with (UX Design Doc Appendix B, "Stored
/// defaults"), in the order the strip offers them. They ship in the app and
/// are laid over the user's rows at read time; none is ever stored as it
/// is, and a changed or deleted one is a row that names it by its seed.
///
/// Sheet sizes are seeded per unit system — 48in × 96in under Imperial,
/// 1200 × 2400 mm under Metric — where the prototype seeded metric sheets
/// in inches (47.24in × 94.49in); Appendix D records that its walkthrough
/// screens show the prototype's seeds. Masonry pieces and footing
/// cross-sections have one set, quoted in inches by the trade in both
/// systems. Every length is whole ticks, rounded as the parser rounds a
/// typed value, and spelled in the unit the seed was quoted in. A seed's
/// key is its store and its value ("sheet_48x96in"), so it stays the same
/// across builds and phones.
abstract final class TradeStoreSeeds {
  /// The seed sizes of one store under one unit system.
  static List<StoredSize> sizes(SizeStore store, MeasurementSystem system) =>
      switch (store) {
        SizeStore.sheet => switch (system) {
          MeasurementSystem.imperial => _sizes(store, const [
            (48, 96),
            (48, 108),
            (48, 120),
          ], Unit.inch),
          MeasurementSystem.metric => _sizes(store, const [
            (1200, 2400),
            (1200, 2700),
            (1200, 3000),
          ], Unit.millimetre),
        },
        SizeStore.masonry => _sizes(store, const [(8, 16), (4, 8)], Unit.inch),
        SizeStore.footing => _sizes(store, const [
          (16, 8),
          (24, 18),
        ], Unit.inch),
      };

  /// The on-centre spacings: 16in, 24in.
  static List<StoredSpacing> get spacings => [
    for (final (index, inches) in const [16, 24].indexed)
      StoredSpacing(
        spacing: _length(inches, Unit.inch),
        position: index,
        seed: 'spacing_$inches${Unit.inch.suffix}',
      ),
  ];

  /// The fence: O.C. 8ft, 3 rails per section.
  static FenceConfiguration get fence =>
      FenceConfiguration(onCentre: _length(8, Unit.foot), railsPerSection: 3);

  /// The waste factor of every unit: 0% until the Waste pill is edited.
  static List<StoredWaste> get waste => [
    for (final unit in RateUnit.values) StoredWaste(unit: unit),
  ];

  /// The densities in lbs/yd³: concrete, gravel, sand.
  static const List<StoredDensity> densities = [
    StoredDensity(
      name: 'concrete',
      poundsPerCubicYard: 4050,
      position: 0,
      seed: 'density_concrete',
    ),
    StoredDensity(
      name: 'gravel',
      poundsPerCubicYard: 3000,
      position: 1,
      seed: 'density_gravel',
    ),
    StoredDensity(
      name: 'sand',
      poundsPerCubicYard: 2700,
      position: 2,
      seed: 'density_sand',
    ),
  ];

  static List<StoredSize> _sizes(
    SizeStore store,
    List<(int, int)> sizes,
    Unit unit,
  ) => [
    for (final (index, (width, height)) in sizes.indexed)
      StoredSize(
        store: store,
        width: _length(width, unit),
        height: _length(height, unit),
        position: index,
        seed: '${store.name}_${width}x$height${unit.suffix}',
      ),
  ];

  static Length _length(int value, Unit unit) =>
      Length((value * unit.ticksPerUnit).round(), unit: unit);
}
