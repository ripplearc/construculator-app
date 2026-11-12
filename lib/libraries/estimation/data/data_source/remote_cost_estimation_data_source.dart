import 'package:construculator/libraries/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Supabase-backed implementation of [CostEstimationDataSource].
/// Wraps [SupabaseWrapper] calls for single-row reads on the cost estimates
/// table.
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
}
