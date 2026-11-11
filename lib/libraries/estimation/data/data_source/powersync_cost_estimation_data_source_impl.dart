import 'dart:async';

import 'package:construculator/libraries/estimation/data/data_source/interfaces/powersync_cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart' show uuid;

/// PowerSync-backed [PowerSyncCostEstimationDataSource].
///
/// Talks to the [PowerSyncDatabaseWrapper] seam: reads through reactive
/// `watch()` streams over local SQLite and activates the on-demand
/// `user_cost_estimates` sync stream lazily on the first watch subscription.
/// Rows come back as `Map<String, dynamic>` and are mapped to DTOs via
/// [CostEstimateDto.fromRow], which handles SQLite encodings (e.g. `is_locked`
/// as `0`/`1`). Writes go through [PowerSyncDatabaseWrapper.writeTransaction].
/// A rename or lock change first reads the row, to tell whether the phone has
/// it and whether the value already matches.
///
/// `_table` backs onto the local SQLite table defined in `schema.dart`.
/// `_syncStreamName` names the on-demand sync stream gating which estimates
/// sync down; membership and the `get_cost_estimations` permission are
/// derived from the JWT server-side.
class PowerSyncCostEstimationDataSourceImpl
    implements PowerSyncCostEstimationDataSource {
  final PowerSyncDatabaseWrapper _wrapper;
  static final _logger = AppLogger().tag('PowerSyncCostEstimationDataSource');

  static const _table = DatabaseConstants.costEstimatesTable;

  static const _syncStreamName = 'user_cost_estimates';

  PowerSyncCostEstimationDataSourceImpl({required this._wrapper});

  @override
  Stream<List<CostEstimateDto>> watchEstimations({
    required String projectId,
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) {
    final sql = _buildSelectSql(
      sortBy: sortBy,
      ascending: ascending,
      limited: limit != null,
    );
    return _watchWithSyncStream(
      sql: sql,
      parameters: _selectParameters(projectId, limit),
      mapRows: (rows) => rows.map(CostEstimateDto.fromRow).toList(),
      // `watch` fires on any change to `cost_estimates`, so an unrelated
      // project's row would otherwise rebuild an identical list. Lists compare
      // by identity under plain `==`, so this needs element-wise equality.
      dedupeWith: listEquals,
      logMessage:
          'Activating sync stream "$_syncStreamName" and watching estimates '
          'for project: $projectId',
    );
  }

  @override
  Stream<CostEstimateDto?> watchEstimationById({required String id}) {
    return _watchWithSyncStream(
      sql: _buildSelectByIdSql(),
      parameters: [id],
      mapRows: (rows) =>
          rows.isEmpty ? null : CostEstimateDto.fromRow(rows.first),
      // `watch` fires on any change to `cost_estimates`, so an unrelated
      // estimate would otherwise rebuild this row into an identical DTO.
      // CostEstimateDto is Equatable, so plain value equality is enough.
      dedupeWith: (previous, next) => previous == next,
      logMessage:
          'Activating sync stream "$_syncStreamName" and watching estimate: $id',
    );
  }

  // The on-demand sync stream is activated only for the subscription's lifetime.
  Stream<T> _watchWithSyncStream<T>({
    required String sql,
    required List<Object?> parameters,
    required T Function(List<Map<String, dynamic>> rows) mapRows,
    required String logMessage,
    bool Function(T previous, T next)? dedupeWith,
  }) {
    return Stream<T>.multi((controller) async {
      SyncStreamHandle? handle;
      StreamSubscription<T>? subscription;
      var listenerCancelled = false;

      void releaseHandle() {
        final currentHandle = handle;
        handle = null;
        currentHandle?.unsubscribe();
      }

      controller.onCancel = () async {
        listenerCancelled = true;
        await subscription?.cancel();
        subscription = null;
        releaseHandle();
      };

      _logger.debug(logMessage);

      try {
        handle = await _wrapper.syncStream(_syncStreamName);
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        await controller.close();
        return;
      }

      if (listenerCancelled || !controller.hasListener) {
        releaseHandle();
        return;
      }

      final mapped = _wrapper.watch(sql, parameters: parameters).map(mapRows);
      subscription =
          (dedupeWith != null ? mapped.distinct(dedupeWith) : mapped).listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );

      if (listenerCancelled || !controller.hasListener) {
        await subscription?.cancel();
        subscription = null;
        releaseHandle();
      }
    });
  }

  @override
  Future<List<CostEstimateDto>> getEstimations({
    required String projectId,
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) async {
    _logger.debug(
      'Reading one-shot snapshot of estimates for project: $projectId',
    );
    final sql = _buildSelectSql(
      sortBy: sortBy,
      ascending: ascending,
      limited: limit != null,
    );
    final rows = await _wrapper.getAll(
      sql,
      _selectParameters(projectId, limit),
    );
    return rows.map(CostEstimateDto.fromRow).toList();
  }

  String _buildSelectSql({
    required EstimationSortOption sortBy,
    required bool ascending,
    required bool limited,
  }) {
    final orderColumn = sortBy == EstimationSortOption.updatedAt
        ? DatabaseConstants.updatedAtColumn
        : DatabaseConstants.createdAtColumn;
    final direction = ascending ? 'ASC' : 'DESC';
    final limitClause = limited ? ' LIMIT ?' : '';
    return 'SELECT * FROM $_table WHERE ${DatabaseConstants.projectIdColumn} = ? '
        'ORDER BY $orderColumn $direction$limitClause';
  }

  String _buildSelectByIdSql() =>
      'SELECT * FROM $_table WHERE ${DatabaseConstants.idColumn} = ? LIMIT 1';

  List<Object?> _selectParameters(String projectId, int? limit) => [
    projectId,
    ?limit,
  ];

  @override
  Future<CostEstimateDto?> loadEstimationById(String id) async {
    final rows = await _wrapper.getAll(_buildSelectByIdSql(), [id]);
    return rows.isEmpty ? null : CostEstimateDto.fromRow(rows.first);
  }

  @override
  Future<CostEstimateDto> insertEstimationRow(
    CostEstimateDto estimation,
  ) async {
    final id = estimation.id.isEmpty ? uuid.v4() : estimation.id;
    final row = {
      DatabaseConstants.idColumn: id,
      ...estimation.toJson(),
      DatabaseConstants.isLockedColumn: estimation.isLocked ? 1 : 0,
    };
    final columns = row.keys.join(', ');
    final placeholders = List.filled(row.length, '?').join(', ');
    await _wrapper.writeTransaction(
      (tx) => tx.execute(
        'INSERT INTO $_table ($columns) VALUES ($placeholders)',
        row.values.toList(),
      ),
    );
    return CostEstimateDto.fromRow(row);
  }

  @override
  Future<CostEstimateDto?> updateEstimationNameById({
    required String id,
    required String newName,
  }) => _updateColumnById(id, DatabaseConstants.estimateNameColumn, newName);

  @override
  Future<CostEstimateDto?> updateEstimationLockById({
    required String id,
    required bool isLocked,
  }) =>
      _updateColumnById(id, DatabaseConstants.isLockedColumn, isLocked ? 1 : 0);

  @override
  Future<void> deleteEstimationRowById(String id) => _wrapper.writeTransaction(
    (tx) => tx.execute(
      'DELETE FROM $_table WHERE ${DatabaseConstants.idColumn} = ?',
      [id],
    ),
  );

  // TODO: [CA-1451] Let the upload skip an update the server no longer finds, so one refused write does not block the queue.
  // https://ripplearc.youtrack.cloud/issue/CA-1451
  Future<CostEstimateDto?> _updateColumnById(
    String id,
    String column,
    Object value,
  ) async {
    final rows = await _wrapper.getAll(_buildSelectByIdSql(), [id]);
    if (rows.isEmpty) return null;
    if (rows.first[column] == value) return CostEstimateDto.fromRow(rows.first);
    await _wrapper.writeTransaction(
      (tx) => tx.execute(
        'UPDATE $_table SET $column = ? '
        'WHERE ${DatabaseConstants.idColumn} = ?',
        [value, id],
      ),
    );
    final updatedRows = await _wrapper.getAll(_buildSelectByIdSql(), [id]);
    return updatedRows.isEmpty
        ? null
        : CostEstimateDto.fromRow(updatedRows.first);
  }
}
