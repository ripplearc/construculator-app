import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';

/// Interface that abstracts cost estimation data source operations.
/// This allows the cost estimation service to work with any cost estimation backend.
abstract class CostEstimationDataSource {
  /// Used to fetch one cost estimation by its ID.
  ///
  /// Returns the matching [CostEstimateDto], or null when no row has this ID.
  Future<CostEstimateDto?> getEstimationById(String estimationId);
}
