import 'dart:async';

import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// A [FakePowerSyncDatabaseWrapper] that remembers what is written to the
/// `your_rates` and `current_company` tables, so a write in one test step is
/// what a read in the next step finds, with no signal involved.
///
/// The base fake scripts each answer by SQL text. This one emulates only the
/// statements `LocalYourRatesDataSource` and
/// `PowerSyncLocalCurrentCompanyDataSource` issue: for `your_rates` the
/// filtered `SELECT`, the `SELECT` by id, an `INSERT` and an `UPDATE` by id;
/// for `current_company` a `SELECT` by user id, an `INSERT` and a `DELETE`.
/// Statements are still recorded in [executeCalls] and [getAllCalls].
class FakeYourRatesDatabase extends FakePowerSyncDatabaseWrapper {
  final List<Map<String, Object?>> _rows = [];

  /// Every row an `INSERT` has added since the last [reset], as stored.
  final List<Map<String, Object?>> insertedRows = [];

  /// The id of every row an `UPDATE` has changed since the last [reset].
  final List<Object?> updatedRowIds = [];

  static final _statementTable = RegExp(
    r'(?:FROM|INTO|UPDATE)\s+(\w+)',
    caseSensitive: false,
  );
  static final _insertColumns = RegExp(r'\(([^)]*)\)\s*VALUES');
  static final _updateAssignments = RegExp(r'SET\s+(.+?)\s+WHERE');
  static final _assignedColumns = RegExp(r'(\w+)\s*=\s*\?');
  static final _nullableFilterColumns = RegExp(
    r'\?\s+IS\s+NULL\s+OR\s+(\w+)\s*=\s*\?',
  );
  static final _singleFilterColumn = RegExp(r'WHERE\s+(\w+)\s*=\s*\?\s*$');

  /// While set, every read waits for it to complete, so a test can hold a
  /// read open and look at the loading state.
  Completer<void>? getAllGate;

  final List<Map<String, Object?>> _companyRows = [];

  /// Keeps [companyId] on the phone for [userId], as a sign-in with signal
  /// would have.
  void keepCompanyOnPhone({required String userId, required String companyId}) {
    _companyRows.add({
      DatabaseConstants.userIdColumn: userId,
      DatabaseConstants.companyIdColumn: companyId,
    });
  }

  /// Puts [rows] on the phone as though sync had delivered them.
  void seedRows(List<Map<String, Object?>> rows) => rows.forEach(seedRow);

  /// Puts [row] on the phone as though sync had delivered it.
  void seedRow(Map<String, Object?> row) => _rows.add(Map.of(row));

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await super.getAll(sql, parameters);
    if (sql.contains(DatabaseConstants.currentCompanyTable)) {
      return [
        for (final row in _companyRows)
          if (row[DatabaseConstants.userIdColumn] == parameters.single)
            {
              DatabaseConstants.companyIdColumn:
                  row[DatabaseConstants.companyIdColumn],
            },
      ];
    }
    _requireYourRatesTable(sql);
    await getAllGate?.future;

    final filters = <String, Object?>{};
    final nullableFilters = _nullableFilterColumns.allMatches(sql).toList();
    if (nullableFilters.isNotEmpty) {
      for (var i = 0; i < nullableFilters.length; i++) {
        filters[nullableFilters[i].group(1)!] = parameters[i * 2 + 1];
      }
    } else {
      filters[_singleFilterColumn.firstMatch(sql)!.group(1)!] =
          parameters.single;
    }
    _requireKnownColumns(filters.keys, sql);
    return [
      for (final row in _rows)
        if (filters.entries.every(
          (filter) => filter.value == null || row[filter.key] == filter.value,
        ))
          {...row},
    ];
  }

  @override
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await super.execute(sql, parameters);
    if (sql.contains(DatabaseConstants.currentCompanyTable)) {
      if (sql.startsWith('DELETE')) {
        _companyRows.clear();
      } else {
        keepCompanyOnPhone(
          userId: parameters[1] as String,
          companyId: parameters[2] as String,
        );
      }
      return;
    }
    _requireYourRatesTable(sql);
    if (sql.startsWith('INSERT')) {
      final columns = _insertColumns
          .firstMatch(sql)!
          .group(1)!
          .split(',')
          .map((column) => column.trim())
          .toList();
      _requireKnownColumns(columns, sql);
      final inserted = <String, Object?>{
        for (var i = 0; i < columns.length; i++) columns[i]: parameters[i],
      };
      _rows.add(inserted);
      insertedRows.add(inserted);
    } else if (sql.startsWith('UPDATE')) {
      final assigned = _assignedColumns
          .allMatches(_updateAssignments.firstMatch(sql)!.group(1)!)
          .map((match) => match.group(1)!)
          .toList();
      final filterColumn = _singleFilterColumn.firstMatch(sql)!.group(1)!;
      _requireKnownColumns([...assigned, filterColumn], sql);
      final row = _rows.firstWhere(
        (candidate) => candidate[filterColumn] == parameters.last,
        orElse: () => const {},
      );
      if (row.isEmpty) return;
      updatedRowIds.add(row[DatabaseConstants.idColumn]);
      for (var i = 0; i < assigned.length; i++) {
        row[assigned[i]] = parameters[i];
      }
    }
  }

  void _requireYourRatesTable(String sql) {
    final table = _statementTable.firstMatch(sql)?.group(1);
    if (table != DatabaseConstants.yourRatesTable) {
      throw StateError('no such table $table in: $sql');
    }
  }

  void _requireKnownColumns(Iterable<String> columns, String sql) {
    final known = {
      DatabaseConstants.idColumn,
      ...schema.tables
          .firstWhere((table) => table.name == DatabaseConstants.yourRatesTable)
          .columns
          .map((column) => column.name),
    };
    final unknown = columns.where((column) => !known.contains(column));
    if (unknown.isNotEmpty) {
      throw StateError('no such column ${unknown.join(', ')} in: $sql');
    }
  }

  @override
  void reset() {
    super.reset();
    _rows.clear();
    _companyRows.clear();
    getAllGate = null;
    insertedRows.clear();
    updatedRowIds.clear();
  }
}
