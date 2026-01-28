import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

class RemoteCostEstimationDataSource implements CostEstimationDataSource {
  final SupabaseWrapper supabaseWrapper;
  final AppLogger _logger;

  /// database table names and columns
  static const String costEstimatesTable = DatabaseConstants.costEstimatesTable;
  static const String projectIdColumn = DatabaseConstants.projectIdColumn;

  RemoteCostEstimationDataSource({
    required this.supabaseWrapper,
    required AppLogger appLogger,
  }) : _logger = appLogger.tag('RemoteCostEstimationDataSource');

  @override
  Future<List<CostEstimateDto>> getEstimations(String projectId) async {
    try {
      _logger.debug('Getting cost estimations for project: $projectId');
      final response = await supabaseWrapper.select(
        table: costEstimatesTable,
        filterColumn: projectIdColumn,
        filterValue: projectId,
      );

      if (response.isEmpty) {
        _logger.warning('No cost estimations found for project: $projectId');

        return [];
      }

      return response
          .map((costEstimate) => CostEstimateDto.fromJson(costEstimate))
          .toList();
    } catch (e) {
      _logger.error('Error getting cost estimations: $e');
      rethrow;
    }
  }

  @override
  Future<CostEstimateDto> createEstimation(CostEstimateDto estimation) async {
    try {
      _logger.debug('Creating cost estimation: ${estimation.id}');
      final response = await supabaseWrapper.insert(
        table: costEstimatesTable,
        data: estimation.toJson(),
      );

      return CostEstimateDto.fromJson(response);
    } catch (e) {
      _logger.error('Error creating cost estimation: $e');
      rethrow;
    }
  }

  @override
  Future<CostEstimateDto> deleteEstimation(String estimationId) async {
    try {
      _logger.debug('Deleting cost estimation: $estimationId');
      final deletedData = await supabaseWrapper.delete(
        table: costEstimatesTable,
        filterColumn: 'id',
        filterValue: estimationId,
      );
      final deletedDto = CostEstimateDto.fromJson(deletedData);
      _logger.debug('Successfully deleted cost estimation: $estimationId');
      return deletedDto;
    } catch (e) {
      _logger.error('Error deleting cost estimation: $e');
      rethrow;
    }
  }
}
