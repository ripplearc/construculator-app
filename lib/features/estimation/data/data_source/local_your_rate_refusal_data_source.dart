import 'dart:async';

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

  // The refusal, unless the phone now holds a price for the same item and
  // label that is neither the refused price nor the last accepted one: a newer
  // save, on this phone or synced down from another, has replaced them.
  static const _selectWhilePhonePriceIsOursSql =
      'SELECT refusal.* FROM ${DatabaseConstants.yourRateRefusalsTable} refusal '
      'WHERE refusal.${DatabaseConstants.idColumn} = ? AND NOT EXISTS ('
      'SELECT 1 FROM ${DatabaseConstants.yourRatesTable} rate '
      'WHERE rate.${DatabaseConstants.companyIdColumn} = '
      'refusal.${DatabaseConstants.companyIdColumn} '
      'AND rate.${DatabaseConstants.categoryColumn} = '
      'refusal.${DatabaseConstants.categoryColumn} '
      'AND rate.${DatabaseConstants.itemNameColumn} = '
      'refusal.${DatabaseConstants.itemNameColumn} '
      'AND rate.${DatabaseConstants.equipmentMethodColumn} IS '
      'refusal.${DatabaseConstants.equipmentMethodColumn} '
      'AND rate.${DatabaseConstants.entryLabelColumn} IS '
      'refusal.${DatabaseConstants.entryLabelColumn} '
      'AND rate.${DatabaseConstants.rateAmountColumn} != '
      'refusal.${DatabaseConstants.refusedAmountColumn} '
      'AND (refusal.${DatabaseConstants.acceptedAmountColumn} IS NULL '
      'OR rate.${DatabaseConstants.rateAmountColumn} != '
      'refusal.${DatabaseConstants.acceptedAmountColumn}))';

  static const _selectAllSql =
      'SELECT * FROM ${DatabaseConstants.yourRateRefusalsTable}';

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

  @override
  Future<List<YourRateRefusalDto>> loadAllRefusals() async {
    try {
      final rows = await _database.getAll(_selectAllSql);
      return rows.map(YourRateRefusalDto.fromJson).toList();
    } catch (e, stack) {
      _logger.error('Failed to read refused defaults from the phone', e, stack);
      rethrow;
    }
  }

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
  Stream<YourRateRefusalDto?> watchRefusalByItem({
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  }) {
    return _database
        .watch(
          _selectWhilePhonePriceIsOursSql,
          parameters: [_keyOf(companyId, category, itemName, equipmentMethod)],
        )
        .map(
          (rows) =>
              rows.isEmpty ? null : YourRateRefusalDto.fromJson(rows.first),
        )
        .distinct()
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stack, sink) {
              _logger.error(
                'Failed to watch a refused default on the phone',
                error,
                stack,
              );
              sink.addError(error, stack);
            },
          ),
        );
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
