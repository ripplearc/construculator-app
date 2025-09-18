import 'package:construculator/features/estimation/data/data_sources/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimation_dto.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_entity.dart';

class CostEstimationRepositoryImpl implements CostEstimationRepository {
  final CostEstimationDataSource dataSource;

  CostEstimationRepositoryImpl({required this.dataSource});

  @override
  Future<List<CostEstimate>> getEstimations(String projectId) async {
    final dtos = await dataSource.getEstimations(projectId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }
}
