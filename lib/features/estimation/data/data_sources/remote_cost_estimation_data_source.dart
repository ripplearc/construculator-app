import 'package:construculator/features/estimation/data/data_sources/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimation_dto.dart';

class RemoteCostEstimationDataSourceImpl implements CostEstimationDataSource {
  @override
  Future<List<CostEstimationDto>> getEstimations(String projectId) async {
    return [];
  }
}
