import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';

/// Interface that abstracts cost estimation data source operations.
/// This allows the cost estimation service to work with any cost estimation backend.
abstract class CostEstimationDataSource {
  /// Used to get all cost estimations
  ///
  /// Returns a [CostEstimateDto] with the cost estimations.
  Future<List<CostEstimateDto>> getEstimations(String projectId);

  /// Used to create a new cost estimation
  ///
  /// Returns a [CostEstimateDto] with the created cost estimation.
  Future<CostEstimateDto> createEstimation(CostEstimateDto estimation);

  /// Deletes a cost estimation by its ID.
  Future<void> deleteEstimation(String estimationId);
}
