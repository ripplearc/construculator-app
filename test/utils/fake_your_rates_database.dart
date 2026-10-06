import 'dart:async';

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

  static const _writableColumns = [
    DatabaseConstants.companyIdColumn,
    DatabaseConstants.categoryColumn,
    DatabaseConstants.itemNameColumn,
    DatabaseConstants.rateAmountColumn,
    DatabaseConstants.rateCurrencyColumn,
    DatabaseConstants.unitColumn,
    DatabaseConstants.equipmentMethodColumn,
    DatabaseConstants.entryLabelColumn,
    DatabaseConstants.savedAtColumn,
  ];

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
    await getAllGate?.future;
    if (parameters.length == 1) {
      return [
        for (final row in _rows)
          if (row[DatabaseConstants.idColumn] == parameters.single) {...row},
      ];
    }
    final [companyId, _, category, _] = parameters;
    return [
      for (final row in _rows)
        if ((companyId == null ||
                row[DatabaseConstants.companyIdColumn] == companyId) &&
            (category == null ||
                row[DatabaseConstants.categoryColumn] == category))
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
    } else if (sql.startsWith('INSERT')) {
      final inserted = <String, Object?>{
        DatabaseConstants.idColumn: parameters[0],
        for (var i = 0; i < _writableColumns.length; i++)
          _writableColumns[i]: parameters[i + 1],
        DatabaseConstants.createdAtColumn: parameters[10],
        DatabaseConstants.updatedAtColumn: parameters[11],
      };
      _rows.add(inserted);
      insertedRows.add(inserted);
    } else if (sql.startsWith('UPDATE')) {
      final row = _rows.firstWhere(
        (candidate) => candidate[DatabaseConstants.idColumn] == parameters.last,
        orElse: () => const {},
      );
      if (row.isEmpty) return;
      updatedRowIds.add(parameters.last);
      for (var i = 0; i < _writableColumns.length; i++) {
        row[_writableColumns[i]] = parameters[i];
      }
      row[DatabaseConstants.updatedAtColumn] = parameters[9];
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
