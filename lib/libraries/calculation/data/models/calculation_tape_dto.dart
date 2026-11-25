import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// One row of the local-only `calculator_tapes` table (`schema.dart`,
/// Design Appendices D and E): the chip list of one session as JSON, with
/// the version of the JSON format it was written in.
///
/// The row keeps the JSON as text and leaves its reading to the codec,
/// which checks [schemaVersion] before it reads a chip, so a tape written
/// by a later build is refused on read, never half-read. A row a column of
/// which cannot be read is a [FormatException].
class CalculationTapeDto extends Equatable {
  /// The row id.
  final String id;

  /// The session the tape belongs to.
  final String sessionId;

  /// The chip list as JSON text.
  final String computation;

  /// The version of the JSON format [computation] was written in.
  final int schemaVersion;

  /// When the row was written.
  final DateTime createdAt;

  const CalculationTapeDto({
    required this.id,
    required this.sessionId,
    required this.computation,
    required this.schemaVersion,
    required this.createdAt,
  });

  /// A row as SQLite hands it back.
  factory CalculationTapeDto.fromRow(Map<String, Object?> row) =>
      CalculationTapeDto(
        id: _text(row, DatabaseConstants.idColumn),
        sessionId: _text(row, DatabaseConstants.sessionIdColumn),
        computation: _text(row, DatabaseConstants.computationColumn),
        schemaVersion: switch (row[DatabaseConstants.schemaVersionColumn]) {
          final int version => version,
          _ => throw const FormatException(
            'Unreadable tape row: ${DatabaseConstants.schemaVersionColumn}',
          ),
        },
        createdAt:
            DateTime.tryParse(_text(row, DatabaseConstants.createdAtColumn)) ??
            (throw const FormatException(
              'Unreadable tape row: ${DatabaseConstants.createdAtColumn}',
            )),
      );

  /// The row's columns, the id included.
  Map<String, Object?> toRow() => {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.sessionIdColumn: sessionId,
    DatabaseConstants.computationColumn: computation,
    DatabaseConstants.schemaVersionColumn: schemaVersion,
    DatabaseConstants.createdAtColumn: createdAt.toUtc().toIso8601String(),
  };

  static String _text(Map<String, Object?> row, String column) =>
      switch (row[column]) {
        final String text => text,
        _ => throw FormatException('Unreadable tape row: $column'),
      };

  @override
  List<Object?> get props => [
    id,
    sessionId,
    computation,
    schemaVersion,
    createdAt,
  ];
}
