import 'dart:convert';

import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// The wire values of `calculator_store_kind_enum`: which trade store a
/// `user_calculator_stores` row belongs to. Seven kinds since CA-1398
/// dropped `rate`; the rates are the company's `your_rates` rows (CA-1304).
enum CalculatorStoreKind {
  /// Drywall sheet sizes.
  sheetSize('sheet_size'),

  /// Masonry piece sizes.
  masonryPiece('masonry_piece'),

  /// Footing cross-sections.
  footingSection('footing_section'),

  /// On-centre spacings.
  onCentreSpacing('on_centre_spacing'),

  /// The one fence configuration.
  fenceConfig('fence_config'),

  /// The waste factor per rate unit.
  waste('waste'),

  /// Named densities.
  density('density');

  /// The enum label as the server spells it.
  final String wire;

  const CalculatorStoreKind(this.wire);

  /// The kind spelled [wire]; a [FormatException] for a label this build
  /// does not know, since the row cannot be read.
  static CalculatorStoreKind fromWire(String wire) => values.firstWhere(
    (kind) => kind.wire == wire,
    orElse: () => throw FormatException('Unknown calculator store kind: $wire'),
  );
}

/// One `user_calculator_stores` row (Design Appendices B): an entry the
/// user added or changed in one trade store, its fields as a JSON object
/// whose keys the row mapper owns.
///
/// Timestamps are the phone's, in UTC; the server stamps `updated_at` itself
/// on every update it applies. [deletedAt] set is a soft delete: the row
/// stays so every phone hides the same entry, or the default it stands for.
class CalculatorStoreRowDto extends Equatable {
  /// The key under which a changed default names the default it replaces.
  static const String seedKey = DatabaseConstants.seedKey;

  /// The row's id, `null` before it is stored.
  final String? id;

  /// The account the entry belongs to: `users.id`.
  final String userId;

  /// Which store the entry is in.
  final CalculatorStoreKind storeKind;

  /// The entry's fields.
  final Map<String, Object?> values;

  /// The unit system the entry was typed under.
  final MeasurementSystem unitSystem;

  /// When the phone stored the entry.
  final DateTime createdAt;

  /// When the entry was last written.
  final DateTime updatedAt;

  /// When the entry was deleted, `null` while it is live.
  final DateTime? deletedAt;

  const CalculatorStoreRowDto({
    this.id,
    required this.userId,
    required this.storeKind,
    required this.values,
    required this.unitSystem,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// The default this row stands in for, `null` for an entry the user added.
  String? get seed => values[seedKey] as String?;

  /// Whether the row is a soft delete.
  bool get isDeleted => deletedAt != null;

  /// Reads a row of the local table. The JSON object in `values` is decoded
  /// here; a row that cannot be read is a [FormatException], because only
  /// the app writes these rows and a bad one means the table is not what
  /// the schema says.
  factory CalculatorStoreRowDto.fromRow(Map<String, Object?> row) {
    final decoded = jsonDecode(_text(row, DatabaseConstants.valuesColumn));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Unreadable trade store row: ${DatabaseConstants.valuesColumn}',
      );
    }
    return CalculatorStoreRowDto(
      id: _text(row, DatabaseConstants.idColumn),
      userId: _text(row, DatabaseConstants.userIdColumn),
      storeKind: CalculatorStoreKind.fromWire(
        _text(row, DatabaseConstants.storeKindColumn),
      ),
      values: decoded,
      unitSystem: _system(_text(row, DatabaseConstants.unitSystemColumn)),
      createdAt: _time(row, DatabaseConstants.createdAtColumn),
      updatedAt: _time(row, DatabaseConstants.updatedAtColumn),
      deletedAt: row[DatabaseConstants.deletedAtColumn] == null
          ? null
          : _time(row, DatabaseConstants.deletedAtColumn),
    );
  }

  /// The row's columns, without its id, as the local table takes them:
  /// `values` encoded as JSON text and every timestamp in UTC.
  Map<String, Object?> toColumns() {
    final deleted = deletedAt;
    return {
      DatabaseConstants.userIdColumn: userId,
      DatabaseConstants.storeKindColumn: storeKind.wire,
      DatabaseConstants.valuesColumn: jsonEncode(values),
      DatabaseConstants.unitSystemColumn: unitSystem.name,
      DatabaseConstants.createdAtColumn: _iso(createdAt),
      DatabaseConstants.updatedAtColumn: _iso(updatedAt),
      DatabaseConstants.deletedAtColumn: deleted == null ? null : _iso(deleted),
    };
  }

  /// Returns a copy with the given fields replaced. [deletedAt] is replaced
  /// when [clearDeletedAt] is set, so a deleted default can be brought back.
  CalculatorStoreRowDto copyWith({
    String? id,
    Map<String, Object?>? values,
    MeasurementSystem? unitSystem,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => CalculatorStoreRowDto(
    id: id ?? this.id,
    userId: userId,
    storeKind: storeKind,
    values: values ?? this.values,
    unitSystem: unitSystem ?? this.unitSystem,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static MeasurementSystem _system(String name) =>
      MeasurementSystem.values.asNameMap()[name] ??
      (throw const FormatException(
        'Unreadable trade store row: ${DatabaseConstants.unitSystemColumn}',
      ));

  static String _text(Map<String, Object?> row, String column) {
    if (row[column] case final String value) return value;
    throw FormatException('Unreadable trade store row: $column');
  }

  static DateTime _time(Map<String, Object?> row, String column) {
    final parsed = DateTime.tryParse(_text(row, column));
    if (parsed == null) {
      throw FormatException('Unreadable trade store row: $column');
    }
    return parsed;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    storeKind,
    values,
    unitSystem,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
