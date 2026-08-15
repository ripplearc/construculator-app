// coverage:ignore-file
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';

/// Reactive, PowerSync-backed read data source for cost estimations.
///
/// Reads go through `watch()` so the UI stays live as sync arrives. Unlike the
/// request/response [CostEstimationDataSource], this seam owns activation of the
/// on-demand `user_cost_estimates` sync stream. It returns DTOs (no `Either`)
/// and always rethrows; the repository is the error boundary. Write operations
/// (create/delete/rename/lock) are added in later PRs.
abstract class PowerSyncCostEstimationDataSource {
  /// Watches the cost estimates for [projectId] from local SQLite, ordered by
  /// [sortBy] in the given [ascending] direction and optionally capped to
  /// [limit] rows (null means no cap).
  ///
  /// Activates the on-demand `user_cost_estimates` sync stream on the first
  /// subscription and releases it when that subscription is cancelled. The
  /// returned stream re-emits on every local or synced change and is the single
  /// source of truth — callers must not patch results by hand after a write.
  Stream<List<CostEstimateDto>> watchEstimations({
    required String projectId,
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  });

  /// Watches a single cost estimate by [id] from local SQLite, re-emitting on
  /// every local or synced change to that row.
  ///
  /// Emits `null` when no row matches — either because the estimate has not yet
  /// synced down or because it was deleted — so the UI can react to the row
  /// appearing and disappearing. Like [watchEstimations], it activates the
  /// on-demand `user_cost_estimates` sync stream on the first subscription and
  /// releases it when that subscription is cancelled, and remains the single
  /// source of truth — callers must not patch the result by hand after a write.
  Stream<CostEstimateDto?> watchEstimationById({required String id});

  /// Reads a one-shot snapshot of the cost estimates for [projectId] from local
  /// SQLite, ordered by [sortBy] in the given [ascending] direction and
  /// optionally capped to [limit] rows (null means no cap).
  ///
  /// Does not activate the sync stream; use [watchEstimations] for live reads.
  Future<List<CostEstimateDto>> getEstimations({
    required String projectId,
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  });
}
