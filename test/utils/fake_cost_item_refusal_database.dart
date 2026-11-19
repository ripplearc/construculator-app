import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:sqlite3/common.dart';

/// A [FakePowerSyncDatabase] for tests of the upload step that remembers the
/// phone's `cost_items` rows and the rows of the local-only
/// `cost_item_refusals` table.
///
/// It emulates only the statements the connector issues for a refused cost
/// line: the `SELECT` of one `cost_items` row by id, an `INSERT OR REPLACE`
/// into `cost_item_refusals` and a `DELETE` from it by id. It reads the SQL
/// text, so a column the schema does not have, or a placeholder count that
/// does not match the parameters, fails the way SQLite would.
class FakeCostItemRefusalDatabase extends FakePowerSyncDatabase {
  final Map<String, Map<String, Object?>> _costItemsById = {};
  final Map<String, Map<String, Object?>> _refusalsById = {};

  /// When set, every statement throws it, so a test can fail the write of a
  /// refusal record.
  Object? statementError;

  static final _insertColumns = RegExp(r'\(([^)]*)\)\s*VALUES');
  static final _placeholders = RegExp(r'\?');

  static final _refusalColumns = {
    DatabaseConstants.idColumn,
    ...schema.tables
        .singleWhere(
          (table) => table.name == DatabaseConstants.costItemRefusalsTable,
        )
        .columns
        .map((column) => column.name),
  };

  /// Puts [row] in `cost_items` as the phone's copy of a cost line.
  void seedCostItem(Map<String, Object?> row) {
    _costItemsById[row[DatabaseConstants.idColumn]! as String] = Map.of(row);
  }

  /// Every refusal record now in the table, by the id of its cost line.
  Map<String, Map<String, Object?>> get refusals => {
    for (final entry in _refusalsById.entries) entry.key: {...entry.value},
  };

  @override
  void reset() {
    super.reset();
    _costItemsById.clear();
    _refusalsById.clear();
    statementError = null;
  }

  @override
  Future<Row?> getOptional(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final error = statementError;
    if (error != null) throw error;
    if (!sql.contains(
      'FROM ${DatabaseConstants.costItemsTable} WHERE '
      '${DatabaseConstants.idColumn} = ?',
    )) {
      throw StateError('FakeCostItemRefusalDatabase cannot run: $sql');
    }
    final row = _costItemsById[parameters.single];
    if (row == null) return null;
    final columns = row.keys.toList();
    return ResultSet(columns, null, [
      [for (final column in columns) row[column]],
    ]).first;
  }

  @override
  Future<ResultSet> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final error = statementError;
    if (error != null) throw error;
    final upperSql = sql.trimLeft().toUpperCase();
    if (upperSql.startsWith(
      'INSERT OR REPLACE INTO '
      '${DatabaseConstants.costItemRefusalsTable.toUpperCase()}',
    )) {
      _insertRefusal(sql, parameters);
    } else if (upperSql.startsWith(
      'DELETE FROM ${DatabaseConstants.costItemRefusalsTable.toUpperCase()} '
      'WHERE ${DatabaseConstants.idColumn.toUpperCase()} = ?',
    )) {
      _refusalsById.remove(parameters.single);
    } else {
      throw StateError('FakeCostItemRefusalDatabase cannot run: $sql');
    }
    return ResultSet(const [], null, const []);
  }

  void _insertRefusal(String sql, List<Object?> parameters) {
    final columns = _insertColumns
        .firstMatch(sql)!
        .group(1)!
        .split(',')
        .map((column) => column.trim())
        .toList();
    final unknown = columns.where(
      (column) => !_refusalColumns.contains(column),
    );
    if (unknown.isNotEmpty) {
      throw StateError(
        '${DatabaseConstants.costItemRefusalsTable} has no column named '
        '${unknown.first}',
      );
    }
    final values = sql.substring(sql.toUpperCase().indexOf('VALUES'));
    if (_placeholders.allMatches(values).length != parameters.length ||
        columns.length != parameters.length) {
      throw StateError('Statement and parameters differ in length: $sql');
    }
    final row = {
      for (var i = 0; i < columns.length; i++) columns[i]: parameters[i],
    };
    _refusalsById[row[DatabaseConstants.idColumn]! as String] = row;
  }
}
