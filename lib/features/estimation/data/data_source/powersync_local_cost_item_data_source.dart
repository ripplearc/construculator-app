import 'dart:convert';

import 'package:construculator/features/estimation/data/data_source/interfaces/local_cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:flutter/foundation.dart';

/// Reads and writes cost lines in the phone's own PowerSync database.
///
/// A write lands in local SQLite at once and PowerSync uploads it when a
/// signal returns. No sync stream delivers `cost_items` yet, so a read finds
/// the lines written on this phone that have not uploaded yet, plus uploaded
/// lines until PowerSync removes them at the next checkpoint.
///
/// A line's upload is waiting while PowerSync's `ps_crud` queue holds an entry
/// for it. Each entry is JSON text with the table name and the row id, and
/// PowerSync deletes it when the connector completes the upload. The connector
/// also completes it when the server refuses the line for good (an RLS denial,
/// code 42501), so a refused line leaves the queue too.
///
/// A line the server refused for good is kept as JSON in the local-only
/// `cost_item_refusals` table (see the connector), which [loadRefusedLineTotalsByEstimateId]
/// reads.
///
/// A failed read or write is logged here, at the storage boundary, and
/// rethrown for the repository to translate. A failed watch arrives as an
/// error on the stream, and the repository logs it.
class PowerSyncLocalCostItemDataSource implements LocalCostItemDataSource {
  final PowerSyncDatabaseWrapper _database;
  static final _logger = AppLogger().tag('PowerSyncLocalCostItemDataSource');

  static const _selectByEstimateSql =
      'SELECT * FROM ${DatabaseConstants.costItemsTable} '
      'WHERE ${DatabaseConstants.estimateIdColumn} = ? '
      'ORDER BY ${DatabaseConstants.createdAtColumn} ASC, '
      '${DatabaseConstants.idColumn} ASC';

  static const _selectRefusedByEstimateSql =
      'SELECT ${DatabaseConstants.idColumn}, ${DatabaseConstants.lineColumn} '
      'FROM ${DatabaseConstants.costItemRefusalsTable} '
      'WHERE ${DatabaseConstants.estimateIdColumn} = ?';

  static const _pendingUploadsSql =
      'SELECT ${DatabaseConstants.idColumn} '
      'FROM ${DatabaseConstants.costItemsTable} '
      'WHERE ${DatabaseConstants.estimateIdColumn} = ? '
      'AND ${DatabaseConstants.idColumn} IN ('
      "SELECT json_extract(data, '\$.id') FROM ps_crud "
      "WHERE json_extract(data, '\$.type') = "
      "'${DatabaseConstants.costItemsTable}')";

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

  @override
  Future<Map<String, double>> loadRefusedLineTotalsByEstimateId(
    String estimateId,
  ) async {
    try {
      final rows = await _database.getAll(_selectRefusedByEstimateSql, [
        estimateId,
      ]);
      return {
        for (final row in rows)
          row[DatabaseConstants.idColumn] as String: _itemTotalCostOf(
            row[DatabaseConstants.lineColumn] as String,
          ),
      };
    } catch (e, stack) {
      _logger.error(
        'Failed to read refused cost lines from the phone',
        e,
        stack,
      );
      rethrow;
    }
  }

  static double _itemTotalCostOf(String lineJson) {
    final line = jsonDecode(lineJson) as Map<String, dynamic>;
    return (line[DatabaseConstants.itemTotalCostColumn] as num?)?.toDouble() ??
        0;
  }

  @override
  Stream<Set<String>> watchCostItemIdsWithPendingUpload(String estimateId) {
    return _database
        .watch(_pendingUploadsSql, parameters: [estimateId])
        .map(
          (rows) => {
            for (final row in rows) row[DatabaseConstants.idColumn] as String,
          },
        )
        .distinct(setEquals);
  }
}
