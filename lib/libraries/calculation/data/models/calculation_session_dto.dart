import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// One row of the local-only `calculator_sessions` table (`schema.dart`,
/// Design Appendices E), column for column.
///
/// The result is laid flat the way a remembered value is: its dimension's
/// name, its canonical magnitude and the unit it was spelled in. A row a
/// column of which cannot be read — a dimension or unit name this build
/// does not know included — is a [FormatException], because a session is
/// only ever written by this class and a bad one means the table is not
/// what the schema says. Timestamps are ISO-8601 text in UTC.
class CalculationSessionDto extends Equatable {
  /// The row id.
  final String id;

  /// The account signed in when the tape was banked.
  final String creatorUserId;

  /// The card's name, or `null`.
  final String? title;

  /// The last result as it read when banked, or `null`.
  final String? resultText;

  /// The last result's value, or `null`.
  final Quantity? result;

  /// When the row was written.
  final DateTime createdAt;

  /// When the row last changed.
  final DateTime updatedAt;

  /// When the tape was last banked into this session.
  final DateTime lastCalculationAt;

  const CalculationSessionDto({
    required this.id,
    required this.creatorUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastCalculationAt,
    this.title,
    this.resultText,
    this.result,
  });

  /// The row of [session].
  factory CalculationSessionDto.fromEntity(CalculationSession session) =>
      CalculationSessionDto(
        id: session.id,
        creatorUserId: session.creatorUserId,
        title: session.title,
        resultText: session.resultText,
        result: session.result,
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        lastCalculationAt: session.lastCalculationAt,
      );

  /// A row as SQLite hands it back.
  factory CalculationSessionDto.fromRow(Map<String, Object?> row) =>
      CalculationSessionDto(
        id: _text(row, DatabaseConstants.idColumn),
        creatorUserId: _text(row, DatabaseConstants.creatorUserIdColumn),
        title: _optionalText(row, DatabaseConstants.titleColumn),
        resultText: _optionalText(row, DatabaseConstants.resultTextColumn),
        result: _result(row),
        createdAt: _time(row, DatabaseConstants.createdAtColumn),
        updatedAt: _time(row, DatabaseConstants.updatedAtColumn),
        lastCalculationAt: _time(
          row,
          DatabaseConstants.lastCalculationAtColumn,
        ),
      );

  /// The session this row keeps.
  CalculationSession toEntity() => CalculationSession(
    id: id,
    creatorUserId: creatorUserId,
    title: title,
    resultText: resultText,
    result: result,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastCalculationAt: lastCalculationAt,
  );

  /// The row's columns, the id included.
  Map<String, Object?> toRow() => {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.creatorUserIdColumn: creatorUserId,
    DatabaseConstants.titleColumn: title,
    DatabaseConstants.resultTextColumn: resultText,
    DatabaseConstants.resultValueColumn: switch (result) {
      final Quantity value => _magnitude(value),
      null => null,
    },
    DatabaseConstants.resultDimensionColumn: result?.dimension.name,
    DatabaseConstants.resultUnitColumn: switch (result) {
      Length(:final unit) ||
      Area(:final unit) ||
      Volume(:final unit) ||
      Weight(:final unit) => unit.name,
      Angle() || Scalar() || null => null,
    },
    DatabaseConstants.createdAtColumn: createdAt.toUtc().toIso8601String(),
    DatabaseConstants.updatedAtColumn: updatedAt.toUtc().toIso8601String(),
    DatabaseConstants.lastCalculationAtColumn: lastCalculationAt
        .toUtc()
        .toIso8601String(),
  };

  static double _magnitude(Quantity value) => switch (value) {
    Length() => value.preciseTicks,
    Area() => value.squareTicks,
    Volume() => value.cubicFeet,
    Weight() => value.hundredthsOfPound,
    Angle() => value.degrees,
    Scalar() => value.value,
  };

  static Quantity? _result(Map<String, Object?> row) {
    final dimension = _optionalText(
      row,
      DatabaseConstants.resultDimensionColumn,
    );
    if (dimension == null) return null;
    final magnitude = row[DatabaseConstants.resultValueColumn];
    if (magnitude is! num) {
      throw const FormatException(
        'Unreadable session row: ${DatabaseConstants.resultValueColumn}',
      );
    }
    final value = magnitude.toDouble();
    return switch (Dimension.values.asNameMap()[dimension]) {
      Dimension.length => Length.computed(value, unit: _unit(row)),
      Dimension.area => Area(value, unit: _unit(row)),
      Dimension.volume => Volume(value, unit: _unit(row)),
      Dimension.weight => Weight(value, unit: _unit(row)),
      Dimension.angle => Angle(value),
      Dimension.scalar => Scalar(value),
      null => throw FormatException(
        'Unreadable session row: ${DatabaseConstants.resultDimensionColumn}',
      ),
    };
  }

  static Unit _unit(Map<String, Object?> row) =>
      Unit.values.asNameMap()[_text(row, DatabaseConstants.resultUnitColumn)] ??
      (throw const FormatException(
        'Unreadable session row: ${DatabaseConstants.resultUnitColumn}',
      ));

  static String _text(Map<String, Object?> row, String column) =>
      _optionalText(row, column) ??
      (throw FormatException('Unreadable session row: $column'));

  static String? _optionalText(Map<String, Object?> row, String column) =>
      switch (row[column]) {
        final String text => text,
        null => null,
        _ => throw FormatException('Unreadable session row: $column'),
      };

  static DateTime _time(Map<String, Object?> row, String column) =>
      DateTime.tryParse(_text(row, column)) ??
      (throw FormatException('Unreadable session row: $column'));

  @override
  List<Object?> get props => [
    id,
    creatorUserId,
    title,
    resultText,
    result,
    createdAt,
    updatedAt,
    lastCalculationAt,
  ];
}
