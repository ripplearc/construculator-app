import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// Reads and writes the rows of the local-only `calculator_recents` table
/// in `schema.dart`, column for column.
///
/// A row is a [Quantity] laid flat: its dimension's name, its canonical
/// magnitude and the unit it is spelled in (empty for an angle or a bare
/// number). A length's whole ticks ride in the real column and come back
/// as the same whole number. A row a column of which cannot be read, a
/// dimension or unit name this build does not know included, is a
/// [FormatException], because a recent is only ever written by this class
/// and a bad one means the table is not what the schema says.
abstract final class RecentRowMapper {
  /// The row of [value] at [position] in [drawer], without its id.
  static Map<String, Object> toRow(
    String drawer,
    int position,
    Quantity value,
  ) => {
    DatabaseConstants.drawerColumn: drawer,
    DatabaseConstants.positionColumn: position,
    DatabaseConstants.dimensionColumn: value.dimension.name,
    DatabaseConstants.magnitudeColumn: _magnitude(value),
    DatabaseConstants.unitColumn: _unit(value),
  };

  /// The value a row remembers.
  static Quantity quantityFromRow(Map<String, Object?> row) {
    final magnitude = _real(row, DatabaseConstants.magnitudeColumn);
    return switch (_dimensionOf(row)) {
      Dimension.length => Length(magnitude.round(), unit: _unitOf(row)),
      Dimension.area => Area(magnitude, unit: _unitOf(row)),
      Dimension.volume => Volume(magnitude, unit: _unitOf(row)),
      Dimension.weight => Weight(magnitude, unit: _unitOf(row)),
      Dimension.angle => Angle(magnitude),
      Dimension.scalar => Scalar(magnitude),
    };
  }

  static double _magnitude(Quantity value) => switch (value) {
    Length(:final ticks) => ticks.toDouble(),
    Area(:final squareTicks) => squareTicks,
    Volume(:final cubicFeet) => cubicFeet,
    Weight(:final hundredthsOfPound) => hundredthsOfPound,
    Angle(:final degrees) => degrees,
    Scalar(:final value) => value,
  };

  static String _unit(Quantity value) => switch (value) {
    Length(:final unit) ||
    Area(:final unit) ||
    Volume(:final unit) ||
    Weight(:final unit) => unit.name,
    Angle() || Scalar() => '',
  };

  static Dimension _dimensionOf(Map<String, Object?> row) =>
      Dimension.values.asNameMap()[_text(
        row,
        DatabaseConstants.dimensionColumn,
      )] ??
      (throw const FormatException(
        'Unreadable recent row: ${DatabaseConstants.dimensionColumn}',
      ));

  static Unit _unitOf(Map<String, Object?> row) =>
      Unit.values.asNameMap()[_text(row, DatabaseConstants.unitColumn)] ??
      (throw const FormatException(
        'Unreadable recent row: ${DatabaseConstants.unitColumn}',
      ));

  static String _text(Map<String, Object?> row, String column) {
    if (row[column] case final String value) return value;
    throw FormatException('Unreadable recent row: $column');
  }

  static double _real(Map<String, Object?> row, String column) {
    if (row[column] case final num value) return value.toDouble();
    throw FormatException('Unreadable recent row: $column');
  }
}
