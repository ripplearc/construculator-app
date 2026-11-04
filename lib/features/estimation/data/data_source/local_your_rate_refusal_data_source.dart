import 'package:construculator/features/estimation/data/data_source/interfaces/your_rate_refusal_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_refusal_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// [YourRateRefusalDataSource] over the phone's own database.
class LocalYourRateRefusalDataSource implements YourRateRefusalDataSource {
  final PowerSyncDatabaseWrapper _database;
  final Clock _clock;
  static final _logger = AppLogger().tag('LocalYourRateRefusalDataSource');

  static const _selectByIdSql =
      'SELECT * FROM ${DatabaseConstants.yourRateRefusalsTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _markShownSql =
      'UPDATE ${DatabaseConstants.yourRateRefusalsTable} SET '
      '${DatabaseConstants.shownAtColumn} = ? '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _deleteByIdSql =
      'DELETE FROM ${DatabaseConstants.yourRateRefusalsTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  /// Creates the data source over the phone's [_database]; [_clock] stamps
  /// when a message was shown.
  LocalYourRateRefusalDataSource({
    required this._database,
    required this._clock,
  });

  static String _keyOf(
    String userId,
    String companyId,
    String category,
    String itemName,
    String? equipmentMethod,
  ) => YourRateRefusalKey.of(
    userId: userId,
    companyId: companyId,
    category: category,
    itemName: itemName,
    equipmentMethod: equipmentMethod,
  );

  @override
  Future<YourRateRefusalDto?> loadRefusalByItem({
    required String userId,
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  }) async {
    try {
      final rows = await _database.getAll(_selectByIdSql, [
        _keyOf(userId, companyId, category, itemName, equipmentMethod),
      ]);
      return rows.isEmpty ? null : YourRateRefusalDto.fromJson(rows.first);
    } catch (e, stack) {
      _logger.error(
        'Failed to read a refused default from the phone',
        e,
        stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> markRefusalShownByItem({
    required String userId,
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  }) async {
    try {
      await _database.execute(_markShownSql, [
        _clock.now().toUtc().toIso8601String(),
        _keyOf(userId, companyId, category, itemName, equipmentMethod),
      ]);
    } catch (e, stack) {
      _logger.error('Failed to mark a refusal as shown', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteRefusalByItem({
    required String userId,
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  }) async {
    try {
      await _database.execute(_deleteByIdSql, [
        _keyOf(userId, companyId, category, itemName, equipmentMethod),
      ]);
    } catch (e, stack) {
      _logger.error('Failed to forget a refused default', e, stack);
      rethrow;
    }
  }
}
