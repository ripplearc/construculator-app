import 'dart:async';

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
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

  /// How long the estimate lookup waits for the server before it gives up.
  final Duration lookupTimeout;

  RemoteCostItemDataSource({
    required this._supabaseWrapper,
    this.lookupTimeout = const Duration(seconds: 3),
  });

  @override
  Future<List<CostItemDto>> fetchCostItemsByEstimateId({
    required String estimateId,
    String? itemType,
  }) async {
    _logger.debug(
      'Fetching cost items for estimate: $estimateId'
      '${itemType != null ? ', type: $itemType' : ''}',
    );

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
      _logger.debug(
        'No cost items found for estimate: $estimateId'
        '${itemType != null ? ' with type: $itemType' : ''}',
      );
      return [];
    }

    return response.map((item) => CostItemDto.fromJson(item)).toList();
  }

  @override
  Future<List<double>> fetchItemTotalCostsByEstimateId(
    String estimateId,
  ) async {
    _logger.debug('Fetching item totals for estimate: $estimateId');
    final response = await _supabaseWrapper.select(
      table: DatabaseConstants.costItemsTable,
      columns: DatabaseConstants.itemTotalCostColumn,
      filterColumn: DatabaseConstants.estimateIdColumn,
      filterValue: estimateId,
    );
    return response
        .map(
          (row) =>
              (row[DatabaseConstants.itemTotalCostColumn] as num).toDouble(),
        )
        .toList();
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

  @override
  Future<String?> fetchNewestEstimateNameByEquipmentRate({
    required String companyId,
    required String itemName,
    required String pricingMethod,
    required double rateAmount,
  }) async {
    _logger.debug('Fetching the newest estimate with an equipment rate');
    final rateColumn = pricingMethod == EquipmentPricingMethod.job.toJson()
        ? DatabaseConstants.jobAmountColumn
        : DatabaseConstants.dailyRateColumn;

    // No retry and a short time limit: the "Not kept" message must not wait
    // for a phone with no signal.
    final response = await _supabaseWrapper
        .selectMatch(
          table: DatabaseConstants.costItemsTable,
          columns:
              '${DatabaseConstants.itemNameColumn}, '
              '${DatabaseConstants.costEstimatesTable}'
              '(${DatabaseConstants.estimateNameColumn}, '
              '${DatabaseConstants.projectsTable}'
              '(${DatabaseConstants.owningCompanyIdColumn}))',
          filters: {
            DatabaseConstants.itemTypeColumn: CostItemType.equipment.toJson(),
            DatabaseConstants.pricingMethodColumn: pricingMethod,
            rateColumn: _roundedToStoredPrecision(rateAmount),
          },
          orderBy: DatabaseConstants.createdAtColumn,
          ascending: false,
          retry: false,
        )
        .timeout(lookupTimeout);

    final wantedName = YourRateRefusalKey.normalizeName(itemName);
    final newestLine = response
        .where(
          (line) =>
              YourRateRefusalKey.normalizeName(
                    line[DatabaseConstants.itemNameColumn] as String,
                  ) ==
                  wantedName &&
              _owningCompanyOf(line) == companyId,
        )
        .firstOrNull;
    final estimate =
        newestLine?[DatabaseConstants.costEstimatesTable]
            as Map<String, dynamic>?;
    return estimate?[DatabaseConstants.estimateNameColumn] as String?;
  }

  // A price column holds 4 decimals, so a computed price such as
  // 0.1 + 0.2 must be cut to what the server stores before it is compared.
  static double _roundedToStoredPrecision(double amount) =>
      double.parse(amount.toStringAsFixed(4));

  static String? _owningCompanyOf(Map<String, dynamic> line) {
    final estimate =
        line[DatabaseConstants.costEstimatesTable] as Map<String, dynamic>?;
    final project =
        estimate?[DatabaseConstants.projectsTable] as Map<String, dynamic>?;
    return project?[DatabaseConstants.owningCompanyIdColumn] as String?;
  }
}
