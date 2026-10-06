import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// A [FakePowerSyncDatabaseWrapper] that remembers what is written to the
/// `current_company` table, so a write in one test step is what a read in the
/// next step finds.
///
/// The base fake scripts each answer by SQL text and so cannot show that a
/// saved id comes back, or that another user's row is not returned. This one
/// emulates only the three statements the company data source issues: a
/// `SELECT` filtered by user id, an `INSERT`, and a `DELETE`, including those run inside a write
/// transaction. The statements
/// are still recorded in [executeCalls] and [getAllCalls].
class FakeCurrentCompanyDatabase extends FakePowerSyncDatabaseWrapper {
  final List<Map<String, Object?>> _rows = [];

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await super.getAll(sql, parameters);
    final userId = parameters.single;
    return [
      for (final row in _rows)
        if (row[DatabaseConstants.userIdColumn] == userId)
          {
            DatabaseConstants.companyIdColumn:
                row[DatabaseConstants.companyIdColumn],
          },
    ];
  }

  @override
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await super.execute(sql, parameters);
    _apply(sql, parameters);
  }

  void _apply(String sql, List<Object?> parameters) {
    if (sql.startsWith('DELETE')) {
      _rows.clear();
    } else if (sql.startsWith('INSERT')) {
      _rows.add({
        DatabaseConstants.idColumn: parameters[0],
        DatabaseConstants.userIdColumn: parameters[1],
        DatabaseConstants.companyIdColumn: parameters[2],
      });
    }
  }

  @override
  void reset() {
    super.reset();
    _rows.clear();
  }
}
