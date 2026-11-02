import 'package:construculator/features/calculator/data/models/calculator_store_row_dto.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';

/// Reads and writes the `values` object of a `user_calculator_stores` row,
/// one shape per store kind, and builds the row around it.
///
/// Static functions rather than a DTO per entity: the object is the entity
/// with a tick count where the entity has a [Length], the unit it was
/// spelled in beside it, and an enum name where it has an enum, and nothing
/// else. The keys are this class's, not the database's (the server checks
/// only that `values` is an object). A changed default carries the default's
/// key under [CalculatorStoreRowDto.seedKey]; an entry the user added has
/// no such key. A row's unit system is that of the unit the entry was typed
/// in. A value that cannot be read is a [FormatException], because only
/// this class writes these objects and a bad one means the row is not what
/// the mapper says.
abstract final class TradeStoreRowMapper {
  /// A size's width in whole ticks of 1/64 inch.
  static const String widthTicksKey = 'width_ticks';

  /// A size's height in whole ticks of 1/64 inch.
  static const String heightTicksKey = 'height_ticks';

  /// The unit a length was spelled in: a `Unit` name.
  static const String unitKey = 'unit';

  /// The user's order of an entry within its store, from zero.
  static const String positionKey = 'position';

  /// An on-centre spacing in whole ticks of 1/64 inch.
  static const String ticksKey = 'ticks';

  /// The fence's post spacing in whole ticks of 1/64 inch.
  static const String onCentreTicksKey = 'on_centre_ticks';

  /// The fence's rails between two posts.
  static const String railsPerSectionKey = 'rails_per_section';

  /// A waste factor in percent.
  static const String percentKey = 'percent';

  /// A material's name.
  static const String nameKey = 'name';

  /// A material's density in pounds per cubic yard.
  static const String poundsPerCubicYardKey = 'pounds_per_cubic_yard';

  /// The seed of the one fence row.
  static const String fenceSeed = 'fence';

  /// The store kind a size store's rows carry.
  static CalculatorStoreKind kindOf(SizeStore store) => switch (store) {
    SizeStore.sheet => CalculatorStoreKind.sheetSize,
    SizeStore.masonry => CalculatorStoreKind.masonryPiece,
    SizeStore.footing => CalculatorStoreKind.footingSection,
  };

  /// The size store of a row's kind; `null` for a kind that holds no sizes.
  static SizeStore? storeOf(CalculatorStoreKind kind) => switch (kind) {
    CalculatorStoreKind.sheetSize => SizeStore.sheet,
    CalculatorStoreKind.masonryPiece => SizeStore.masonry,
    CalculatorStoreKind.footingSection => SizeStore.footing,
    CalculatorStoreKind.onCentreSpacing ||
    CalculatorStoreKind.fenceConfig ||
    CalculatorStoreKind.waste ||
    CalculatorStoreKind.density => null,
  };

  /// The unit system a length typed in [unit] belongs to.
  static MeasurementSystem systemOf(Unit unit) =>
      unit.isMetric ? MeasurementSystem.metric : MeasurementSystem.imperial;

  /// The row of a size for [userId], stamped [now].
  static CalculatorStoreRowDto sizeToRow(
    StoredSize size, {
    required String userId,
    required DateTime now,
  }) => _row(
    id: size.id,
    userId: userId,
    kind: kindOf(size.store),
    values: {
      ..._seed(size.seed),
      widthTicksKey: size.width.ticks,
      heightTicksKey: size.height.ticks,
      unitKey: size.width.unit.name,
      positionKey: size.position,
    },
    unitSystem: systemOf(size.width.unit),
    now: now,
  );

  /// A size from its row.
  static StoredSize sizeFromRow(CalculatorStoreRowDto row) {
    final store = storeOf(row.storeKind);
    if (store == null) {
      throw FormatException('Not a size row: ${row.storeKind.wire}');
    }
    final unit = _unit(row.values);
    return StoredSize(
      id: row.id,
      store: store,
      width: Length(_integer(row.values, widthTicksKey), unit: unit),
      height: Length(_integer(row.values, heightTicksKey), unit: unit),
      position: _integer(row.values, positionKey),
      seed: row.seed,
    );
  }

  /// The row of a spacing for [userId], stamped [now].
  static CalculatorStoreRowDto spacingToRow(
    StoredSpacing spacing, {
    required String userId,
    required DateTime now,
  }) => _row(
    id: spacing.id,
    userId: userId,
    kind: CalculatorStoreKind.onCentreSpacing,
    values: {
      ..._seed(spacing.seed),
      ticksKey: spacing.spacing.ticks,
      unitKey: spacing.spacing.unit.name,
      positionKey: spacing.position,
    },
    unitSystem: systemOf(spacing.spacing.unit),
    now: now,
  );

  /// A spacing from its row.
  static StoredSpacing spacingFromRow(CalculatorStoreRowDto row) =>
      StoredSpacing(
        id: row.id,
        spacing: Length(
          _integer(row.values, ticksKey),
          unit: _unit(row.values),
        ),
        position: _integer(row.values, positionKey),
        seed: row.seed,
      );

  /// The row of the fence configuration for [userId], stamped [now]; the
  /// one fence row carries [fenceSeed].
  static CalculatorStoreRowDto fenceToRow(
    FenceConfiguration fence, {
    required String userId,
    required DateTime now,
  }) => _row(
    userId: userId,
    kind: CalculatorStoreKind.fenceConfig,
    values: {
      CalculatorStoreRowDto.seedKey: fenceSeed,
      onCentreTicksKey: fence.onCentre.ticks,
      unitKey: fence.onCentre.unit.name,
      railsPerSectionKey: fence.railsPerSection,
    },
    unitSystem: systemOf(fence.onCentre.unit),
    now: now,
  );

  /// The fence configuration from its row.
  static FenceConfiguration fenceFromRow(CalculatorStoreRowDto row) =>
      FenceConfiguration(
        onCentre: Length(
          _integer(row.values, onCentreTicksKey),
          unit: _unit(row.values),
        ),
        railsPerSection: _integer(row.values, railsPerSectionKey),
      );

  /// The row of a waste factor for [userId], stamped [now]; the unit's name
  /// is the seed, so each unit has one row.
  static CalculatorStoreRowDto wasteToRow(
    StoredWaste waste, {
    required String userId,
    required DateTime now,
  }) => _row(
    userId: userId,
    kind: CalculatorStoreKind.waste,
    values: {
      CalculatorStoreRowDto.seedKey: waste.unit.name,
      percentKey: waste.percent,
    },
    unitSystem: _wasteSystem(waste.unit),
    now: now,
  );

  /// A waste factor from its row; the unit is the row's seed.
  static StoredWaste wasteFromRow(CalculatorStoreRowDto row) => StoredWaste(
    unit: RateUnit.values.byName(
      _text(row.values, CalculatorStoreRowDto.seedKey),
    ),
    percent: _real(row.values, percentKey),
  );

  /// The row of a density for [userId], stamped [now]. Densities are kept in
  /// pounds per cubic yard whatever the display unit, so the row is imperial.
  static CalculatorStoreRowDto densityToRow(
    StoredDensity density, {
    required String userId,
    required DateTime now,
  }) => _row(
    id: density.id,
    userId: userId,
    kind: CalculatorStoreKind.density,
    values: {
      ..._seed(density.seed),
      nameKey: density.name,
      poundsPerCubicYardKey: density.poundsPerCubicYard,
      positionKey: density.position,
    },
    unitSystem: MeasurementSystem.imperial,
    now: now,
  );

  /// A density from its row.
  static StoredDensity densityFromRow(CalculatorStoreRowDto row) =>
      StoredDensity(
        id: row.id,
        name: _text(row.values, nameKey),
        poundsPerCubicYard: _real(row.values, poundsPerCubicYardKey),
        position: _integer(row.values, positionKey),
        seed: row.seed,
      );

  static CalculatorStoreRowDto _row({
    String? id,
    required String userId,
    required CalculatorStoreKind kind,
    required Map<String, Object?> values,
    required MeasurementSystem unitSystem,
    required DateTime now,
  }) => CalculatorStoreRowDto(
    id: id,
    userId: userId,
    storeKind: kind,
    values: values,
    unitSystem: unitSystem,
    createdAt: now,
    updatedAt: now,
  );

  static Map<String, Object?> _seed(String? seed) =>
      seed == null ? const {} : {CalculatorStoreRowDto.seedKey: seed};

  static MeasurementSystem _wasteSystem(RateUnit unit) => switch (unit) {
    RateUnit.squareMetre || RateUnit.cubicMetre => MeasurementSystem.metric,
    RateUnit.squareFoot ||
    RateUnit.squareYard ||
    RateUnit.squareInch ||
    RateUnit.cubicFoot ||
    RateUnit.cubicYard ||
    RateUnit.sheet ||
    RateUnit.thousandBoardFeet => MeasurementSystem.imperial,
  };

  static Unit _unit(Map<String, Object?> values) =>
      Unit.values.byName(_text(values, unitKey));

  static String _text(Map<String, Object?> values, String key) {
    if (values[key] case final String value) return value;
    throw FormatException('Unreadable trade store values: $key');
  }

  static int _integer(Map<String, Object?> values, String key) {
    if (values[key] case final int value) return value;
    throw FormatException('Unreadable trade store values: $key');
  }

  static double _real(Map<String, Object?> values, String key) {
    if (values[key] case final num value) return value.toDouble();
    throw FormatException('Unreadable trade store values: $key');
  }
}
