// coverage:ignore-file
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';

/// Abstract interface for "Your rates" data source operations: the
/// contractor's personal saved-rate book.
///
/// The `companyId` parameter on [loadRates] is what narrows a read to one
/// company: the phone holds the rates of every company the user belongs to.
abstract class YourRatesDataSource {
  /// Loads all your_rates rows visible to the caller, optionally filtered
  /// to one [category], ordered by saved_at descending (most recently saved
  /// first).
  ///
  /// [companyId], when provided, scopes the result to that one company.
  ///
  /// This performs no server-side text search: callers that need to filter
  /// by item name do so themselves against the returned list. See
  /// `YourRatesRepositoryImpl.search` for why.
  ///
  /// [limit], when provided, caps the row count before this method returns. Only
  /// safe to pass when the caller does no further client-side filtering of
  /// the result: passing it alongside a text-search filter would cap the
  /// candidate set before that filter runs, dropping matches that fall
  /// outside the row window.
  ///
  /// Throws an exception if the read fails.
  Future<List<YourRateEntryDto>> loadRates({
    String? category,
    String? companyId,
    int? limit,
  });

  /// Inserts a new row under a newly generated id and returns it.
  ///
  /// Throws an exception if the write fails.
  Future<YourRateEntryDto> insertRate(YourRateEntryDto dto);

  /// Updates the row identified by [id] with [dto]'s field values.
  ///
  /// Throws an exception if the write fails or no row has [id].
  Future<YourRateEntryDto> updateRate(String id, YourRateEntryDto dto);
}
