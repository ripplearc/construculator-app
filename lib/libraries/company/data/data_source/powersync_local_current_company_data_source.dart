import 'package:construculator/libraries/company/data/data_source/interfaces/local_current_company_data_source.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// Keeps the company id in a local-only PowerSync table.
///
/// The table is never uploaded or synced, so the id is read from the phone's
/// own SQLite database with no signal. PowerSync's sign-out clear leaves
/// local-only tables alone (`PowerSyncManagerImpl` passes `clearLocal: false`),
/// so [clearCompanyId] is the only thing that empties this one.
///
/// Failures are logged here, at the storage boundary, and rethrown for the
/// caller to translate.
class PowerSyncLocalCurrentCompanyDataSource
    implements LocalCurrentCompanyDataSource {
  final PowerSyncDatabaseWrapper _database;
  static final _logger = AppLogger().tag(
    'PowerSyncLocalCurrentCompanyDataSource',
  );

  /// Creates a data source over [_database].
  PowerSyncLocalCurrentCompanyDataSource({required this._database});

  static const _rowId = 'current';

  static const _loadSql =
      'SELECT ${DatabaseConstants.companyIdColumn} '
      'FROM ${DatabaseConstants.currentCompanyTable} '
      'WHERE ${DatabaseConstants.userIdColumn} = ?';

  static const _clearSql =
      'DELETE FROM ${DatabaseConstants.currentCompanyTable}';

  static const _insertSql =
      'INSERT INTO ${DatabaseConstants.currentCompanyTable} '
      '(${DatabaseConstants.idColumn}, ${DatabaseConstants.userIdColumn}, '
      '${DatabaseConstants.companyIdColumn}) VALUES (?, ?, ?)';

  @override
  Future<String?> loadCompanyId(String userId) async {
    try {
      final rows = await _database.getAll(_loadSql, [userId]);
      if (rows.isEmpty) return null;
      return rows.first[DatabaseConstants.companyIdColumn] as String?;
    } catch (e, stack) {
      _logger.error('Failed to read the current company id', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> saveCompanyId({
    required String userId,
    required String companyId,
  }) async {
    try {
      await _database.writeTransaction((tx) async {
        await tx.execute(_clearSql);
        await tx.execute(_insertSql, [_rowId, userId, companyId]);
      });
    } catch (e, stack) {
      _logger.error('Failed to keep the current company id', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> clearCompanyId() async {
    try {
      await _database.execute(_clearSql);
    } catch (e, stack) {
      _logger.error('Failed to clear the current company id', e, stack);
      rethrow;
    }
  }
}
