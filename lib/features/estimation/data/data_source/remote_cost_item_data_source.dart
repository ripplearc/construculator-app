import 'package:construculator/features/estimation/data/data_source/interfaces/cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Remote data source for cost item operations using Supabase.
///
/// This data source handles all remote database operations for cost items,
/// including fetching and creating cost items.
///
/// Following Rule 11: Uses explicit method names that clearly indicate
/// network fetch operations with specific scope (by estimate ID).
class RemoteCostItemDataSource implements CostItemDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteCostItemDataSource');

  RemoteCostItemDataSource({required SupabaseWrapper supabaseWrapper})
      : _supabaseWrapper = supabaseWrapper;

  @override
  Future<List<CostItemDto>> fetchCostItemsByEstimateId({
    required String estimateId,
    String? itemType,
  }) async {
    _logger.debug(
      'Fetching cost items for estimate: $estimateId'
      '${itemType != null ? ', type: $itemType' : ''}',
    );

    // Build filters dynamically based on whether itemType is provided
    final filters = <String, dynamic>{
      DatabaseConstants.estimateIdColumn: estimateId,
    };

    if (itemType != null) {
      filters[DatabaseConstants.itemTypeColumn] = itemType;
    }

    final response = await _supabaseWrapper.selectMatch(
      table: DatabaseConstants.costItemsTable,
      filters: filters,
      orderBy: DatabaseConstants.createdAtColumn,
      ascending: true,
    );

    if (response.isEmpty) {
      _logger.warning(
        'No cost items found for estimate: $estimateId'
        '${itemType != null ? ' with type: $itemType' : ''}',
      );
      return [];
    }

    return response.map((item) => CostItemDto.fromJson(item)).toList();
  }

  @override
  Future<CostItemDto> createCostItem(CostItemDto item) async {
    _logger.debug('Creating cost item: ${item.id}');
    final response = await _supabaseWrapper.insert(
      table: DatabaseConstants.costItemsTable,
      data: item.toJson(),
    );

    return CostItemDto.fromJson(response);
  }
}
