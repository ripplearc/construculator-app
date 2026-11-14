import 'dart:convert';

import 'package:construculator/features/estimation/data/data_source/interfaces/local_cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// Reads and writes cost lines in the phone's own PowerSync database.
///
/// A write lands in local SQLite at once and PowerSync uploads it when a
/// signal returns. No sync stream delivers `cost_items` yet, so a read finds
/// only the lines written on this phone.
///
/// Failures are logged here, at the storage boundary, and rethrown for the
/// repository to translate.
class PowerSyncLocalCostItemDataSource implements LocalCostItemDataSource {
  final PowerSyncDatabaseWrapper _database;
  static final _logger = AppLogger().tag('PowerSyncLocalCostItemDataSource');

  static const _selectByEstimateSql =
      'SELECT * FROM ${DatabaseConstants.costItemsTable} '
      'WHERE ${DatabaseConstants.estimateIdColumn} = ? '
      'ORDER BY ${DatabaseConstants.createdAtColumn} ASC';

  /// Creates a data source over [_database].
  PowerSyncLocalCostItemDataSource({required this._database});

  @override
  Future<void> saveCostItemOnPhone(CostItemDto dto) async {
    try {
      final row = {
        ...dto.toJson(),
        DatabaseConstants.calculationColumn: jsonEncode(dto.calculation),
      };
      final columns = row.keys.toList();
      await _database.execute(
        'INSERT OR REPLACE INTO ${DatabaseConstants.costItemsTable} '
        '(${columns.join(', ')}) '
        'VALUES (${List.filled(columns.length, '?').join(', ')})',
        [for (final column in columns) row[column]],
      );
    } catch (e, stack) {
      _logger.error('Failed to save a cost line on the phone', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<CostItemDto>> loadCostItemsByEstimateId(String estimateId) async {
    try {
      final rows = await _database.getAll(_selectByEstimateSql, [estimateId]);
      return rows.map(CostItemDto.fromRow).toList();
    } catch (e, stack) {
      _logger.error('Failed to read cost lines from the phone', e, stack);
      rethrow;
    }
  }
}
