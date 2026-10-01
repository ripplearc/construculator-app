// coverage:ignore-file
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';

/// Abstract interface for "Your rates" data source operations: the
/// contractor's personal saved-rate book.
///
/// Method names are explicit about their operation (fetch from network) and
/// scope. RLS alone does not scope reads to one company: a user who belongs
/// to more than one company (via `company_users`) gets rows from every
/// company they are a member of. The `companyId` parameter on the methods
/// below is the real company scoping; every real caller must resolve and
/// pass one (see [CurrentCompanyResolver]).
abstract class YourRatesDataSource {
  /// Fetches all your_rates rows visible to the caller, optionally filtered
  /// to one [category], ordered by saved_at descending (most recently saved
  /// first).
  ///
  /// [companyId], when provided, scopes the result to that company id. This
  /// is the real scoping for a user who belongs to more than one company —
  /// RLS alone would return rows from every company they are a member of.
  ///
  /// This performs no server-side text search: callers that need to filter
  /// by item name do so themselves against the returned list. See
  /// `YourRatesRepositoryImpl.search` for why.
  ///
  /// Throws an exception if the fetch operation fails.
  Future<List<YourRateEntryDto>> fetchRates({
    String? category,
    String? companyId,
  });

  /// Fetches rows in the exact (category, itemName) grouping.
  ///
  /// [itemName] is matched case-sensitively and exactly — deliberately
  /// different from `YourRatesRepository.search`'s case-insensitive
  /// substring matching. This method identifies the grouping the collision
  /// rule in `YourRatesRepository.save` operates on, and that grouping is
  /// defined by the backend's own unique index on the exact column value;
  /// `search` is a separate, fuzzier lookup for humans finding an item by
  /// name, not the identity check `save` and `getByItemName` need.
  ///
  /// [companyId], when provided, scopes the result to that company id, the
  /// same real-scoping reasoning as [fetchRates]'s [companyId] parameter.
  ///
  /// Used both by `YourRatesRepository.save`'s duplicate detection and by
  /// `YourRatesRepository.getByItemName`.
  ///
  /// Throws an exception if the fetch operation fails.
  Future<List<YourRateEntryDto>> fetchGrouping({
    required String category,
    required String itemName,
    String? companyId,
  });

  /// Inserts a new row, letting the server generate its id.
  ///
  /// Throws an exception if the insert operation fails.
  Future<YourRateEntryDto> insertRate(YourRateEntryDto dto);

  /// Updates the row identified by [id] with [dto]'s field values.
  ///
  /// Throws an exception if the update operation fails.
  Future<YourRateEntryDto> updateRate(String id, YourRateEntryDto dto);
}
