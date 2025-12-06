import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// Implementation of [CostEstimationRepository] that coordinates data access
/// from various data sources to provide cost estimation data to the domain layer.
///
/// This repository implementation follows the repository pattern by:
/// - Abstracting data source operations from the domain layer
/// - Converting data transfer objects (DTOs) to domain entities
/// - Providing a single point of access for cost estimation data operations
/// - Handling data source coordination and error propagation
///
/// The implementation can work with any data source that implements the
/// [CostEstimationDataSource] interface, allowing for flexibility in data
/// source selection (remote APIs, local storage, etc.).
class CostEstimationRepositoryImpl implements CostEstimationRepository {
  final CostEstimationDataSource _dataSource;
  static final _logger = AppLogger().tag('CostEstimationRepositoryImpl');

  /// Creates a new [CostEstimationRepositoryImpl] instance.
  ///
  /// [dataSource] is the data source implementation that will be used
  /// to fetch cost estimation data. This can be a remote data source,
  /// local data source, or any other implementation of [CostEstimationDataSource].
  CostEstimationRepositoryImpl({
    required CostEstimationDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<List<CostEstimate>> getEstimations(String projectId) async {
    try {
      _logger.debug('Getting cost estimations for project: $projectId');
      
      // Fetch DTOs from the data source
      final costEstimateDtos = await _dataSource.getEstimations(projectId);
      
      // Convert DTOs to domain entities
      final costEstimates = costEstimateDtos
          .map((dto) => dto.toDomain())
          .toList();
      
      _logger.debug('Successfully retrieved ${costEstimates.length} cost estimations for project: $projectId');
      
      return costEstimates;
    } catch (e) {
      _logger.error('Error getting cost estimations for project $projectId: $e');
      rethrow;
    }
  }
}
