import 'package:construculator/libraries/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Supabase-backed implementation of [CostEstimationDataSource].
/// Wraps [SupabaseWrapper] calls for single-row reads and write operations
/// on the cost estimates table.
class RemoteCostEstimationDataSource implements CostEstimationDataSource {
  final SupabaseWrapper supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteCostEstimationDataSource');

  /// database table names and columns
  static const String costEstimatesTable = DatabaseConstants.costEstimatesTable;

  RemoteCostEstimationDataSource({required this.supabaseWrapper});

  @override
  Future<CostEstimateDto?> getEstimationById(String estimationId) async {
    _logger.debug('Getting cost estimation: $estimationId');
    final response = await supabaseWrapper.selectSingle(
      table: costEstimatesTable,
      filterColumn: DatabaseConstants.idColumn,
      filterValue: estimationId,
    );
    return response == null ? null : CostEstimateDto.fromJson(response);
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
