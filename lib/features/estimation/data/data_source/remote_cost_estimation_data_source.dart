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

  RemoteCostEstimationDataSource({required this.supabaseWrapper});

  @override
  Future<List<CostEstimateDto>> getEstimations({
    required String projectId,
    required int offset,
    required int limit,
  }) async {
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
  }

  @override
  Future<CostEstimateDto> createEstimation(CostEstimateDto estimation) async {
    _logger.debug('Creating cost estimation: ${estimation.id}');
    final response = await supabaseWrapper.insert(
      table: costEstimatesTable,
      data: estimation.toJson(),
    );

    return CostEstimateDto.fromJson(response);
  }

  @override
  Future<void> deleteEstimation(String estimationId) async {
    _logger.debug('Deleting cost estimation: $estimationId');
    await supabaseWrapper.delete(
      table: costEstimatesTable,
      filterColumn: DatabaseConstants.idColumn,
      filterValue: estimationId,
    );
    _logger.debug('Successfully deleted cost estimation: $estimationId');
  }

  @override
  Future<CostEstimateDto> changeLockStatus({
    required String estimationId,
    required bool isLocked,
  }) async {
    _logger.debug(
      'Changing lock status for estimation: $estimationId to $isLocked',
    );

    final Map<String, dynamic> data = {
      DatabaseConstants.isLockedColumn: isLocked,
    };

    final response = await supabaseWrapper.update(
      table: costEstimatesTable,
      data: data,
      filterColumn: DatabaseConstants.idColumn,
      filterValue: estimationId,
    );

    return CostEstimateDto.fromJson(response);
  }

  @override
  Future<CostEstimateDto> renameEstimation({
    required String estimationId,
    required String newName,
  }) async {
    _logger.debug('Renaming estimation: $estimationId to $newName');

    final response = await supabaseWrapper.update(
      table: costEstimatesTable,
      data: {DatabaseConstants.estimateNameColumn: newName},
      filterColumn: DatabaseConstants.idColumn,
      filterValue: estimationId,
    );

    return CostEstimateDto.fromJson(response);
  }
}
