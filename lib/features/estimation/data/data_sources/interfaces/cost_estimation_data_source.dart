import 'package:construculator/features/estimation/data/models/cost_estimation_dto.dart';

/// An abstract class representing a data source for cost estimations.
abstract class CostEstimationDataSource {
  /// Fetches a list of cost estimation DTOs for a given project ID.
  Future<List<CostEstimationDto>> getEstimations(String projectId);
}
