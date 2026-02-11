import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

class RemoteCostEstimationDataSource implements CostEstimationDataSource {
  final SupabaseWrapper supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteCostEstimationDataSource');

  /// database table names and columns
  static const String costEstimatesTable = DatabaseConstants.costEstimatesTable;
  static const String projectIdColumn = DatabaseConstants.projectIdColumn;
  static const String createdAtColumn = DatabaseConstants.createdAtColumn;

  RemoteCostEstimationDataSource({
    required this.supabaseWrapper,
  });

  @override
  Future<List<CostEstimateDto>> getEstimations({
    required String projectId,
    required int offset,
    required int limit,
  }) async {
    try {
      _logger.debug(
        'Getting cost estimations for project: $projectId, '
        'offset: $offset, limit: $limit',
      );
      final response = await supabaseWrapper.selectPaginated(
        table: costEstimatesTable,
        filterColumn: projectIdColumn,
        filterValue: projectId,
        orderColumn: createdAtColumn,
        ascending: false,
        rangeFrom: offset,
        rangeTo: offset + limit - 1,
      );

      if (response.isEmpty) {
        _logger.warning(
          'No cost estimations found for project: $projectId at offset: $offset',
        );
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
  Future<void> deleteEstimation(String estimationId) async {
    try {
      _logger.debug('Deleting cost estimation: $estimationId');
      await supabaseWrapper.delete(
        table: costEstimatesTable,
        filterColumn: 'id',
        filterValue: estimationId,
      );
      _logger.debug('Successfully deleted cost estimation: $estimationId');
    } catch (e) {
      _logger.error('Error deleting cost estimation: $e');
      rethrow;
    }
  }
}
