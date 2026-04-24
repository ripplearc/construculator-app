import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';

/// Abstract interface for cost item data source operations.
///
/// This interface defines the contract for managing cost items in the data layer.
/// Implementations of this interface handle the actual data operations from various
/// sources (e.g., remote API, local cache).
abstract class CostItemDataSource {
  /// Fetches paginated cost items for a specific estimation.
  ///
  /// Parameters:
  /// - [estimateId]: The ID of the estimation to fetch items for
  /// - [offset]: Starting index for pagination (0-based)
  /// - [limit]: Number of items to fetch
  ///
  /// Returns a list of [CostItemDto] objects representing the cost items.
  ///
  /// Throws an exception if the fetch operation fails.
  Future<List<CostItemDto>> getCostItems({
    required String estimateId,
    required int offset,
    required int limit,
  });

  /// Creates a new cost item.
  ///
  /// Parameters:
  /// - [item]: The cost item DTO to create
  ///
  /// Returns the created [CostItemDto] with server-generated fields populated.
  ///
  /// Throws an exception if the create operation fails.
  Future<CostItemDto> createCostItem(CostItemDto item);
}
