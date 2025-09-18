import 'package:construculator/features/estimation/domain/entities/cost_estimation_entity.dart';

/// An abstract class representing a repository for cost estimations.
abstract class CostEstimationRepository {
  /// Fetches a list of cost estimations for a given project ID.
  Future<List<CostEstimate>> getEstimations(String projectId);
}
