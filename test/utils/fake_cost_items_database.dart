import 'dart:async';

import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// A [FakePowerSyncDatabaseWrapper] that remembers what is written to the
/// `cost_items` table, so a write in one test step is what a read in the next
/// step finds.
///
/// It emulates only the statements `PowerSyncLocalCostItemDataSource` issues:
/// an `INSERT OR REPLACE`, the `SELECT` of one estimate's rows, and the watch
/// of the ids whose upload is still waiting (see [finishUpload]). It reads
/// the SQL text, so a column the schema does not have, or a placeholder count
/// that does not match the parameters, fails the way SQLite would.
///
/// Every row written through `execute` waits in an upload queue, as it does in
/// PowerSync, until [finishUpload] is called for its id. A row put in by
/// [seedRow] is not queued, as a row sync delivered is not.
class FakeCostItemsDatabase extends FakePowerSyncDatabaseWrapper {
  final Map<String, Map<String, Object?>> _rowsById = {};
  final Map<String, Map<String, Object?>> _refusalsById = {};
  final Set<String> _pendingUploadIds = {};
  final StreamController<void> _changes = StreamController.broadcast(
    sync: true,
  );
  final StreamController<Object> _watchFailures = StreamController.broadcast(
    sync: true,
  );

  static final _insertColumns = RegExp(r'\(([^)]*)\)\s*VALUES');
  static final _placeholders = RegExp(r'\?');
  static final _queuedWriteTable = RegExp(
    r"json_extract\(data, '\$\.type'\) = 'cost_items'",
  );
  static final _queuedWriteRowId = RegExp(r"json_extract\(data, '\$\.id'\)");
  static final _membershipInQueue = RegExp(r'(?<!NOT )\bIN \(');
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

  /// When set, reading the refusal records throws it, so a test can fail that
  /// read without failing the read of the lines.
  Object? refusalReadError;

  /// Puts [row] in the `cost_item_refusals` table as the connector writes it
  /// when the server refuses a line.
  void seedRefusal(Map<String, Object?> row) {
    _refusalsById[row[DatabaseConstants.idColumn]! as String] = Map.of(row);
  }

  /// Puts [row] in the table as though sync had delivered it.
  void seedRow(Map<String, Object?> row) {
    _rowsById[row[DatabaseConstants.idColumn]! as String] = Map.of(row);
    _changes.add(null);
  }

  /// Makes every open watch report [error], as a failed read of the phone's
  /// database would.
  void failWatches(Object error) => _watchFailures.add(error);

  /// Takes the row with [id] out of the upload queue, as the server taking
  /// the line does.
  void finishUpload(String id) {
    _pendingUploadIds.remove(id);
    _changes.add(null);
  }

  @override
  void reset() {
    super.reset();
    _rowsById.clear();
    _refusalsById.clear();
    refusalReadError = null;
    _pendingUploadIds.clear();
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = kDefaultWatchThrottle,
  }) {
    final column = _estimateFilter.firstMatch(sql)?.group(1);
    if (!sql.contains('FROM ${DatabaseConstants.costItemsTable}') ||
        !sql.contains('ps_crud') ||
        column == null) {
      throw StateError('FakeCostItemsDatabase cannot watch: $sql');
    }
    if (!_knownColumns.contains(column)) {
      throw StateError('cost_items has no column named $column');
    }
    if (!_queuedWriteTable.hasMatch(sql) ||
        !_queuedWriteRowId.hasMatch(sql) ||
        !_membershipInQueue.hasMatch(sql)) {
      throw StateError(
        'A ps_crud entry holds the table in "type" and the row in "id", and '
        'a line is waiting while its id is IN the queue: $sql',
      );
    }
    watchCalls.add((sql: sql, parameters: parameters));
    List<Map<String, dynamic>> current() => [
      for (final row in _rowsById.values)
        if (row[column] == parameters.single &&
            _pendingUploadIds.contains(row[DatabaseConstants.idColumn]))
          {DatabaseConstants.idColumn: row[DatabaseConstants.idColumn]},
    ];
    return Stream.multi((listener) {
      listener.add(current());
      final subscription = _changes.stream.listen(
        (_) => listener.add(current()),
      );
      final failures = _watchFailures.stream.listen(listener.addError);
      listener.onCancel = () {
        failures.cancel();
        return subscription.cancel();
      };
    });
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
    final id = row[DatabaseConstants.idColumn]! as String;
    _rowsById[id] = row;
    _pendingUploadIds.add(id);
    _changes.add(null);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await super.getAll(sql, parameters);
    if (sql.contains('FROM ${DatabaseConstants.costItemRefusalsTable}')) {
      return _refusedLines(sql, parameters);
    }
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

  List<Map<String, dynamic>> _refusedLines(
    String sql,
    List<Object?> parameters,
  ) {
    final error = refusalReadError;
    if (error != null) throw error;
    if (!sql.contains('WHERE ${DatabaseConstants.estimateIdColumn} = ?')) {
      throw StateError('FakeCostItemsDatabase cannot run: $sql');
    }
    return [
      for (final row in _refusalsById.values)
        if (row[DatabaseConstants.estimateIdColumn] == parameters.single)
          {
            DatabaseConstants.idColumn: row[DatabaseConstants.idColumn],
            DatabaseConstants.lineColumn: row[DatabaseConstants.lineColumn],
          },
    ];
  }
}
