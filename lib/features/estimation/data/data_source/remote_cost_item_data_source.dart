import 'package:construculator/features/estimation/data/data_source/interfaces/cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Remote data source for cost item operations using Supabase.
///
/// This data source handles all remote database operations for cost items,
/// including fetching, creating, updating, and deleting cost items.
class RemoteCostItemDataSource implements CostItemDataSource {
  final SupabaseWrapper supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteCostItemDataSource');

  static const String _itemTypeColumn = 'item_type';

  RemoteCostItemDataSource({required this.supabaseWrapper});

  @override
  Future<List<CostItemDto>> getCostItems({
    required String estimateId,
    required int offset,
    required int limit,
  }) async {
    _logger.debug(
      'Getting cost items for estimate: $estimateId, '
      'offset: $offset, limit: $limit',
    );

    final response = await supabaseWrapper.selectPaginated(
      table: DatabaseConstants.costItemsTable,
      filterColumn: DatabaseConstants.estimateIdColumn,
      filterValue: estimateId,
      orderColumn: DatabaseConstants.createdAtColumn,
      ascending: true,
      rangeFrom: offset,
      rangeTo: offset + limit - 1,
    );

    if (response.isEmpty) {
      _logger.warning(
        'No cost items found for estimate: $estimateId at offset: $offset',
      );
      return [];
    }

    return response.map((item) => CostItemDto.fromJson(item)).toList();
  }

  @override
  Future<CostItemDto> createCostItem(CostItemDto item) async {
    _logger.debug('Creating cost item: ${item.id}');
    final response = await supabaseWrapper.insert(
      table: DatabaseConstants.costItemsTable,
      data: item.toJson(),
    );

    return CostItemDto.fromJson(response);
  }

  /// Fetches cost items filtered by type for a specific estimate.
  ///
  /// Returns a list of [CostItemDto] matching the specified item type,
  /// ordered by creation date (oldest first).
  ///
  /// Note: This is a convenience method not part of the interface.
  /// For paginated access, use [getCostItems] instead.
  Future<List<CostItemDto>> getCostItemsByType({
    required String estimateId,
    required String itemType,
  }) async {
    _logger.debug(
      'Getting cost items for estimate: $estimateId, type: $itemType',
    );

    final response = await supabaseWrapper.selectMatch(
      table: DatabaseConstants.costItemsTable,
      filters: {
        DatabaseConstants.estimateIdColumn: estimateId,
        _itemTypeColumn: itemType,
      },
      orderBy: DatabaseConstants.createdAtColumn,
      ascending: true,
    );

    if (response.isEmpty) {
      _logger.warning(
        'No cost items of type $itemType found for estimate: $estimateId',
      );
      return [];
    }

    return response.map((item) => CostItemDto.fromJson(item)).toList();
  }
}
