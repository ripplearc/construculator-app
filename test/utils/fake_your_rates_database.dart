import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// A [FakePowerSyncDatabaseWrapper] that remembers what is written to the
/// `your_rates` table, so a write in one test step is what a read in the next
/// step finds, with no signal involved.
///
/// The base fake scripts each answer by SQL text. This one emulates only the
/// four statements `LocalYourRatesDataSource` issues: the filtered `SELECT`,
/// the `SELECT` by id, an `INSERT` and an `UPDATE` by id. Statements are still
/// recorded in [executeCalls] and [getAllCalls].
class FakeYourRatesDatabase extends FakePowerSyncDatabaseWrapper {
  final List<Map<String, Object?>> _rows = [];

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

  /// Puts [row] on the phone as though sync had delivered it.
  void seedRow(Map<String, Object?> row) => _rows.add(Map.of(row));

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await super.getAll(sql, parameters);
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
    if (sql.startsWith('INSERT')) {
      _rows.add({
        DatabaseConstants.idColumn: parameters[0],
        for (var i = 0; i < _writableColumns.length; i++)
          _writableColumns[i]: parameters[i + 1],
        DatabaseConstants.createdAtColumn: parameters[10],
        DatabaseConstants.updatedAtColumn: parameters[11],
      });
    } else if (sql.startsWith('UPDATE')) {
      final row = _rows.firstWhere(
        (candidate) => candidate[DatabaseConstants.idColumn] == parameters.last,
        orElse: () => const {},
      );
      if (row.isEmpty) return;
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
  }
}
