import 'dart:async';

import 'package:construculator/libraries/estimation/data/data_source/interfaces/powersync_cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';

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
  static const _table = 'cost_estimates';

  // On-demand sync stream gating which estimates sync down; membership and the
  // `get_cost_estimations` permission are derived from the JWT server-side.
  static const _syncStreamName = 'user_cost_estimates';

  PowerSyncCostEstimationDataSourceImpl({
    required PowerSyncDatabaseWrapper wrapper,
  }) : _wrapper = wrapper;

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
      logMessage:
          'Activating sync stream "$_syncStreamName" and watching estimates '
          'for project: $projectId',
    );
  }

  @override
  Stream<CostEstimateDto?> watchEstimationById({required String id}) {
    return _watchWithSyncStream(
      sql: 'SELECT * FROM $_table WHERE id = ? LIMIT 1',
      parameters: [id],
      mapRows: (rows) =>
          rows.isEmpty ? null : CostEstimateDto.fromRow(rows.first),
      // `watch` fires on any change to `cost_estimates`, so an unrelated
      // estimate would otherwise rebuild this row into an identical DTO.
      dedupe: true,
      logMessage:
          'Activating sync stream "$_syncStreamName" and watching estimate: $id',
    );
  }

  // Watches [sql] as the single source of truth while keeping the on-demand
  // `user_cost_estimates` sync stream active only for the subscription's
  // lifetime.
  //
  // Lazy activation tied to the subscription lifecycle: the on-demand stream is
  // only synced while someone is actually watching it, and is released on
  // cancel. [mapRows] projects each raw result set into the emitted shape T (a
  // list for the collection watch, a nullable DTO for the by-id watch).
  //
  // [dedupe] drops emissions equal to the previous one, for shapes T that have
  // value equality.
  Stream<T> _watchWithSyncStream<T>({
    required String sql,
    required List<Object?> parameters,
    required T Function(List<Map<String, dynamic>> rows) mapRows,
    required String logMessage,
    bool dedupe = false,
  }) {
    return Stream<T>.multi((controller) async {
      SyncStreamHandle? handle;
      StreamSubscription<T>? subscription;
      var listenerCancelled = false;

      Future<void> releaseHandle() async {
        final currentHandle = handle;
        handle = null;
        currentHandle?.unsubscribe();
      }

      controller.onCancel = () async {
        listenerCancelled = true;
        await subscription?.cancel();
        subscription = null;
        await releaseHandle();
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
        await releaseHandle();
        return;
      }

      final rows = _wrapper.watch(sql, parameters: parameters).map(mapRows);
      subscription = (dedupe ? rows.distinct() : rows).listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );

      if (listenerCancelled || !controller.hasListener) {
        await subscription?.cancel();
        subscription = null;
        await releaseHandle();
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
        ? 'updated_at'
        : 'created_at';
    final direction = ascending ? 'ASC' : 'DESC';
    final limitClause = limited ? ' LIMIT ?' : '';
    return 'SELECT * FROM $_table WHERE project_id = ? '
        'ORDER BY $orderColumn $direction$limitClause';
  }

  List<Object?> _selectParameters(String projectId, int? limit) => [
    projectId,
    if (limit != null) limit,
  ];
}
