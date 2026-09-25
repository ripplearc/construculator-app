import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// Reads and writes the trade-store rows of the local-only tables in
/// `schema.dart`, column for column.
///
/// Static functions rather than a DTO per entity: a row is the entity with
/// a tick count where the entity has a [Length] and an enum name where it
/// has an enum, and nothing else. A length row reads back in inches, the
/// unit the trade quotes sizes in (Section 6, "Display settings"); the
/// formatter re-spells it in millimetres under Metric. A row a column of
/// which cannot be read is a [FormatException], because a store row is
/// only ever written by this class and a bad one means the table is not
/// what the schema says.
abstract final class TradeStoreRowMapper {
  /// The row of a size, without its id.
  static Map<String, Object> sizeToRow(StoredSize size) => {
    DatabaseConstants.storeColumn: size.store.name,
    DatabaseConstants.systemColumn: size.system.name,
    DatabaseConstants.widthTicksColumn: size.width.ticks,
    DatabaseConstants.heightTicksColumn: size.height.ticks,
    DatabaseConstants.positionColumn: size.position,
  };

  /// A size from its row.
  static StoredSize sizeFromRow(Map<String, Object?> row) => StoredSize(
    id: _text(row, DatabaseConstants.idColumn),
    store: SizeStore.values.byName(_text(row, DatabaseConstants.storeColumn)),
    system: MeasurementSystem.values.byName(
      _text(row, DatabaseConstants.systemColumn),
    ),
    width: _inches(row, DatabaseConstants.widthTicksColumn),
    height: _inches(row, DatabaseConstants.heightTicksColumn),
    position: _integer(row, DatabaseConstants.positionColumn),
  );

  /// The row of a spacing, without its id.
  static Map<String, Object> spacingToRow(StoredSpacing spacing) => {
    DatabaseConstants.ticksColumn: spacing.spacing.ticks,
    DatabaseConstants.positionColumn: spacing.position,
  };

  /// A spacing from its row.
  static StoredSpacing spacingFromRow(Map<String, Object?> row) =>
      StoredSpacing(
        id: _text(row, DatabaseConstants.idColumn),
        spacing: _inches(row, DatabaseConstants.ticksColumn),
        position: _integer(row, DatabaseConstants.positionColumn),
      );

  /// The row of the fence configuration, without its id.
  static Map<String, Object> fenceToRow(FenceConfiguration fence) => {
    DatabaseConstants.onCentreTicksColumn: fence.onCentre.ticks,
    DatabaseConstants.railsPerSectionColumn: fence.railsPerSection,
  };

  /// The fence configuration from its row; the spacing reads in feet, as
  /// the O.C. pill quotes it.
  static FenceConfiguration fenceFromRow(Map<String, Object?> row) =>
      FenceConfiguration(
        onCentre: Length(
          _integer(row, DatabaseConstants.onCentreTicksColumn),
          unit: Unit.foot,
        ),
        railsPerSection: _integer(row, DatabaseConstants.railsPerSectionColumn),
      );

  /// The row of a rate, without its id.
  static Map<String, Object> rateToRow(StoredRate rate) => {
    DatabaseConstants.unitColumn: rate.unit.name,
    DatabaseConstants.rateColumn: rate.rate,
    DatabaseConstants.wastePercentColumn: rate.wastePercent,
  };

  /// A rate from its row.
  static StoredRate rateFromRow(Map<String, Object?> row) => StoredRate(
    unit: RateUnit.values.byName(_text(row, DatabaseConstants.unitColumn)),
    rate: _real(row, DatabaseConstants.rateColumn),
    wastePercent: _real(row, DatabaseConstants.wastePercentColumn),
  );

  /// The row of a density, without its id.
  static Map<String, Object> densityToRow(StoredDensity density) => {
    DatabaseConstants.nameColumn: density.name,
    DatabaseConstants.poundsPerCubicYardColumn: density.poundsPerCubicYard,
    DatabaseConstants.positionColumn: density.position,
  };

  /// A density from its row.
  static StoredDensity densityFromRow(Map<String, Object?> row) =>
      StoredDensity(
        id: _text(row, DatabaseConstants.idColumn),
        name: _text(row, DatabaseConstants.nameColumn),
        poundsPerCubicYard: _real(
          row,
          DatabaseConstants.poundsPerCubicYardColumn,
        ),
        position: _integer(row, DatabaseConstants.positionColumn),
      );

  static Length _inches(Map<String, Object?> row, String column) =>
      Length(_integer(row, column), unit: Unit.inch);

  static String _text(Map<String, Object?> row, String column) {
    if (row[column] case final String value) return value;
    throw FormatException('Unreadable trade store row: $column');
  }

  static int _integer(Map<String, Object?> row, String column) {
    if (row[column] case final int value) return value;
    throw FormatException('Unreadable trade store row: $column');
  }

  static double _real(Map<String, Object?> row, String column) {
    if (row[column] case final num value) return value.toDouble();
    throw FormatException('Unreadable trade store row: $column');
  }
}
