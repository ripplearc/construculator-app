import 'package:construculator/features/estimation/data/data_sources/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/dto/cost_estimation_dto.dart';
import 'package:construculator/features/estimation/data/repositories/interfaces/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation.dart';

class CostEstimationRepositoryImpl implements CostEstimationRepository {
  final CostEstimationDataSource dataSource;

  CostEstimationRepositoryImpl({required this.dataSource});

  @override
  Future<List<CostEstimation>> getEstimations(String projectId) async {
    final dtos = await dataSource.getEstimations(projectId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }
}

extension on CostEstimationDto {
  CostEstimation toDomain() => CostEstimation(
    id: id,
    projectId: projectId,
    estimateName: estimateName,
    totalCost: totalCost,
    isFavorite: isFavorite,
    isLocked: isLocked,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
