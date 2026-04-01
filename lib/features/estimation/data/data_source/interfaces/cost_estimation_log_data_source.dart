import 'package:construculator/features/estimation/data/models/cost_estimation_log_dto.dart';

/// Abstract interface for cost estimation log data source operations.
///
/// This interface defines the contract for fetching cost estimation logs
/// from the data layer. Implementations of this interface handle the
/// actual data retrieval from various sources (e.g., remote API, local cache).
abstract class CostEstimationLogDataSource {
  /// Fetches paginated logs for a specific estimation.
  ///
  /// Parameters:
  /// - [estimateId]: The ID of the estimation to fetch logs for
  /// - [rangeFrom]: Starting index for pagination (inclusive)
  /// - [rangeTo]: Ending index for pagination (inclusive)
  ///
  /// Returns a list of [CostEstimationLogDto] objects representing the logs.
  ///
  /// Throws an exception if the fetch operation fails.
  Future<List<CostEstimationLogDto>> getEstimationLogs({
    required String estimateId,
    required int rangeFrom,
    required int rangeTo,
  });
}
