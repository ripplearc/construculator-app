import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';

/// Interface that abstracts cost estimation data source operations.
/// This allows the cost estimation service to work with any cost estimation backend.
abstract class CostEstimationDataSource {
  /// Used to get a paginated set of cost estimations
  ///
  /// [projectId] The project to fetch estimations for
  /// [offset] The starting index (0-based)
  /// [limit] The number of items to fetch
  ///
  /// Returns a [List<CostEstimateDto>] for the requested page.
  Future<List<CostEstimateDto>> getEstimations({
    required String projectId,
    required int offset,
    required int limit,
  });

  /// Used to create a new cost estimation
  ///
  /// Returns a [CostEstimateDto] with the created cost estimation.
  Future<CostEstimateDto> createEstimation(CostEstimateDto estimation);

  /// Deletes a cost estimation by its ID.
  Future<void> deleteEstimation(String estimationId);
}
