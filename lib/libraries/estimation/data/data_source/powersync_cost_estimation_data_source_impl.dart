import 'dart:async';

import 'package:construculator/libraries/estimation/data/data_source/interfaces/powersync_cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:flutter/foundation.dart';

/// PowerSync-backed [PowerSyncCostEstimationDataSource].
///
/// Talks to the [PowerSyncDatabaseWrapper] seam: reads through reactive
/// `watch()` streams over local SQLite and activates the on-demand
/// `user_cost_estimates` sync stream lazily on the first watch subscription.
/// Rows come back as `Map<String, dynamic>` and are mapped to DTOs via
/// [CostEstimateDto.fromRow], which handles SQLite encodings (e.g. `is_locked`
/// as `0`/`1`). Write operations are added in later PRs.
class PowerSyncCostEstimationDataSourceImpl
    implements PowerSyncCostEstimationDataSource {
  final PowerSyncDatabaseWrapper _wrapper;
  static final _logger = AppLogger().tag('PowerSyncCostEstimationDataSource');

  // Local SQLite table backing cost estimates (see `schema.dart`).
  static const _table = DatabaseConstants.costEstimatesTable;

  // On-demand sync stream gating which estimates sync down; membership and the
  // `get_cost_estimations` permission are derived from the JWT server-side.
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
    final parameters = _selectParameters(projectId, limit);

    // Lazy activation tied to the subscription lifecycle: the on-demand stream
    // is only synced while someone is actually watching it, and is released on
    // cancel. The watch() stream remains the single source of truth.
    return Stream<List<CostEstimateDto>>.multi((controller) async {
      SyncStreamHandle? handle;
      StreamSubscription<List<CostEstimateDto>>? subscription;
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

      _logger.debug(
        'Activating sync stream "$_syncStreamName" and watching estimates '
        'for project: $projectId',
      );

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

      subscription = _wrapper
          .watch(sql, parameters: parameters)
          .map((rows) => rows.map(CostEstimateDto.fromRow).toList())
          .distinct(listEquals)
          .listen(
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

  List<Object?> _selectParameters(String projectId, int? limit) => [
    projectId,
    ?limit,
  ];
}
