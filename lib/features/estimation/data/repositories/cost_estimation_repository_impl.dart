import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

class CostEstimationRepositoryImpl implements CostEstimationRepository {
  final CostEstimationDataSource _dataSource;
  static final _logger = AppLogger().tag('CostEstimationRepositoryImpl');

  CostEstimationRepositoryImpl({required CostEstimationDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<List<CostEstimate>> getEstimations(String projectId) async {
    try {
      _logger.debug('Getting cost estimations for project: $projectId');

      final costEstimateDtos = await _dataSource.getEstimations(projectId);

      final costEstimates = costEstimateDtos
          .map((dto) => dto.toDomain())
          .toList();

      _logger.debug(
        'Successfully retrieved ${costEstimates.length} cost estimations for project: $projectId',
      );

      return costEstimates;
    } catch (e) {
      _logger.error(
        'Error getting cost estimations for project $projectId: $e',
      );
      rethrow;
    }
  }
}
