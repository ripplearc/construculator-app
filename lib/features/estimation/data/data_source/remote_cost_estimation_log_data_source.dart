import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimation_log_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Remote implementation of [CostEstimationLogDataSource] using Supabase.
///
/// This data source fetches cost estimation logs from the Supabase database.
/// It handles the raw data retrieval and conversion to DTOs, delegating
/// error handling to the repository layer.
class RemoteCostEstimationLogDataSource implements CostEstimationLogDataSource {
  final SupabaseWrapper supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteCostEstimationLogDataSource');

  const RemoteCostEstimationLogDataSource({required this.supabaseWrapper});

  @override
  Future<List<CostEstimationLogDto>> getEstimationLogs({
    required String estimateId,
    required int rangeFrom,
    required int rangeTo,
  }) async {
    _logger.debug(
      'Fetching logs from database: estimateId=$estimateId, range=$rangeFrom-$rangeTo',
    );

    final results = await supabaseWrapper.selectPaginated(
      table: DatabaseConstants.costEstimationLogsTable,
      columns: '*, user:user_profiles(*)',
      filterColumn: DatabaseConstants.estimateIdColumn,
      filterValue: estimateId,
      orderColumn: DatabaseConstants.loggedAtColumn,
      ascending: false,
      rangeFrom: rangeFrom,
      rangeTo: rangeTo,
    );

    _logger.info(
      'Retrieved ${results.length} log entries from database for estimate: $estimateId',
    );

    return results.map((json) => CostEstimationLogDto.fromJson(json)).toList();
  }
}
