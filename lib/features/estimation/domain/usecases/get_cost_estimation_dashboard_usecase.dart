import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_entity.dart';

class GetCostEstimationDashboardUseCase {
  final CostEstimationRepository repository;

  GetCostEstimationDashboardUseCase(this.repository);

  Future<List<CostEstimation>> call(String projectId) {
    return repository.getEstimations(projectId);
  }
}
