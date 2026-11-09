// coverage:ignore-file
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

  /// Fetches only the `item_total_cost` of every live cost item of an
  /// estimate. Soft-deleted items are hidden by the database policy.
  ///
  /// Returns an empty list if the estimate has no items.
  Future<List<double>> fetchItemTotalCostsByEstimateId(String estimateId);

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

  /// Replaces the stored fields of the cost item with [item]'s id.
  ///
  /// Writes every field of [item], so a caller must not change the item type
  /// or the estimate: only the priced fields are meant to differ from what is
  /// stored.
  ///
  /// Returns the updated [CostItemDto] as the server now holds it.
  ///
  /// Throws an exception if no item has that id, or if the update fails.
  Future<CostItemDto> updateCostItem(CostItemDto item);

  /// Deletes the cost item with [itemId].
  ///
  /// The database keeps the row and hides it from every later read (the
  /// `soft_delete_cost_items` migration of the backend turns this delete into
  /// a soft delete), so the item is gone for the app but is not lost for good.
  ///
  /// Throws an exception if the delete fails.
  Future<void> deleteCostItemById(String itemId);

  /// Fetches the name of the estimate of [companyId]'s projects holding the
  /// newest equipment line whose item name is [itemName], priced by
  /// [pricingMethod] ('day' or 'job') at exactly [rateAmount].
  ///
  /// Under day pricing [rateAmount] is compared with the line's daily rate,
  /// under job pricing with its job amount.
  ///
  /// Returns null if no line matches.
  ///
  /// Does not retry, and throws a `TimeoutException` if the server does not
  /// answer within a few seconds.
  ///
  /// Throws an exception if the fetch operation fails due to network or database errors.
  Future<String?> fetchNewestEstimateNameByEquipmentRate({
    required String companyId,
    required String itemName,
    required String pricingMethod,
    required double rateAmount,
  });
}
