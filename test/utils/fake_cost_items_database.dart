import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// A [FakePowerSyncDatabaseWrapper] that remembers what is written to the
/// `cost_items` table, so a write in one test step is what a read in the next
/// step finds.
///
/// It emulates only the statements `PowerSyncLocalCostItemDataSource` issues:
/// an `INSERT OR REPLACE` and the `SELECT` of one estimate's rows. It reads
/// the SQL text, so a column the schema does not have, or a placeholder count
/// that does not match the parameters, fails the way SQLite would.
class FakeCostItemsDatabase extends FakePowerSyncDatabaseWrapper {
  final Map<String, Map<String, Object?>> _rowsById = {};

  static final _insertColumns = RegExp(r'\(([^)]*)\)\s*VALUES');
  static final _placeholders = RegExp(r'\?');
  static final _estimateFilter = RegExp(r'WHERE\s+(\w+)\s*=\s*\?');

  static final _knownColumns = {
    DatabaseConstants.idColumn,
    ...schema.tables
        .singleWhere((table) => table.name == DatabaseConstants.costItemsTable)
        .columns
        .map((column) => column.name),
  };

  /// Every row now in the table, in the order its id was first written.
  List<Map<String, Object?>> get rows => [
    for (final row in _rowsById.values) {...row},
  ];

  /// Puts [row] in the table as though sync had delivered it.
  void seedRow(Map<String, Object?> row) {
    _rowsById[row[DatabaseConstants.idColumn]! as String] = Map.of(row);
  }

  @override
  void reset() {
    super.reset();
    _rowsById.clear();
  }

  @override
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await super.execute(sql, parameters);
    final isInsert = sql.trimLeft().toUpperCase().startsWith(
      'INSERT OR REPLACE INTO ${DatabaseConstants.costItemsTable.toUpperCase()}',
    );
    if (!isInsert) {
      throw StateError('FakeCostItemsDatabase cannot run: $sql');
    }
    final columns = _insertColumns
        .firstMatch(sql)!
        .group(1)!
        .split(',')
        .map((column) => column.trim())
        .toList();
    final unknown = columns.where((column) => !_knownColumns.contains(column));
    if (unknown.isNotEmpty) {
      throw StateError('cost_items has no column named ${unknown.first}');
    }
    final values = sql.substring(sql.toUpperCase().indexOf('VALUES'));
    if (_placeholders.allMatches(values).length != parameters.length ||
        columns.length != parameters.length) {
      throw StateError('Statement and parameters differ in length: $sql');
    }
    final row = {
      for (var i = 0; i < columns.length; i++) columns[i]: parameters[i],
    };
    _rowsById[row[DatabaseConstants.idColumn]! as String] = row;
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await super.getAll(sql, parameters);
    final column = _estimateFilter.firstMatch(sql)?.group(1);
    if (!sql.contains('FROM ${DatabaseConstants.costItemsTable}') ||
        column == null) {
      throw StateError('FakeCostItemsDatabase cannot run: $sql');
    }
    if (!_knownColumns.contains(column)) {
      throw StateError('cost_items has no column named $column');
    }
    final matching = [
      for (final row in _rowsById.values)
        if (row[column] == parameters.single) {...row},
    ];
    if (sql.contains('ORDER BY ${DatabaseConstants.createdAtColumn} ASC')) {
      matching.sort(
        (a, b) => (a[DatabaseConstants.createdAtColumn]! as String).compareTo(
          b[DatabaseConstants.createdAtColumn]! as String,
        ),
      );
    }
    return matching;
  }
}
