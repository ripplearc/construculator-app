import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';

/// Abstract interface for cost item data source operations.
///
/// This interface defines the contract for managing cost items in the data layer.
/// Implementations of this interface handle the actual data operations from various
/// sources (e.g., remote API, local cache).
///
/// Following Rule 11: Method names are explicit about their operations (fetch from network)
/// and scope (by estimate ID, optionally filtered by type).
abstract class CostItemDataSource {
  /// Fetches all cost items from the remote database for a specific estimate,
  /// optionally filtered by item type.
  ///
  /// This method performs a network fetch operation and returns all matching items
  /// ordered by creation date (oldest first).
  ///
  /// Parameters:
  /// - [estimateId]: The ID of the estimation to fetch items for (required)
  /// - [itemType]: Optional type filter. If provided, only items of this type are returned.
  ///               If null, all item types are returned.
  ///
  /// Returns a list of [CostItemDto] objects. Returns an empty list if no items found.
  ///
  /// Throws an exception if the fetch operation fails due to network or database errors.
  Future<List<CostItemDto>> fetchCostItemsByEstimateId({
    required String estimateId,
    String? itemType,
  });

  /// Creates a new cost item in the remote database.
  ///
  /// Parameters:
  /// - [item]: The cost item DTO to create
  ///
  /// Returns the created [CostItemDto] with server-generated fields populated
  /// (id, createdAt, updatedAt).
  ///
  /// Throws an exception if the create operation fails.
  Future<CostItemDto> createCostItem(CostItemDto item);
}
