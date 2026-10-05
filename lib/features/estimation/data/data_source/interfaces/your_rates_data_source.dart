// coverage:ignore-file
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';

/// Abstract interface for "Your rates" data source operations: the
/// contractor's personal saved-rate book.
///
/// Method names are explicit about their operation (fetch from network) and
/// scope. RLS limits the rows a caller can read to the companies they belong
/// to. A caller who belongs to more than one company gets the rows of all of
/// them, and no method here narrows a read to one company yet.
// TODO: [CA-1180](https://ripplearc.youtrack.cloud/issue/CA-1180) Add an explicit company id filter to the reads.
abstract class YourRatesDataSource {
  /// Fetches all your_rates rows visible to the caller, optionally filtered
  /// to one [category], ordered by saved_at descending (most recently saved
  /// first).
  ///
  /// This performs no server-side text search: callers that need to filter
  /// by item name do so themselves against the returned list. See
  /// `YourRatesRepositoryImpl.search` for why.
  ///
  /// [limit], when provided, caps the row count at the database level. Only
  /// safe to pass when the caller does no further client-side filtering of
  /// the result: passing it alongside a text-search filter would cap the
  /// candidate set before that filter runs, dropping matches that fall
  /// outside the row window.
  ///
  /// Throws an exception if the fetch operation fails.
  Future<List<YourRateEntryDto>> fetchRates({String? category, int? limit});

  /// Inserts a new row, letting the server generate its id.
  ///
  /// Throws an exception if the insert operation fails.
  Future<YourRateEntryDto> insertRate(YourRateEntryDto dto);

  /// Updates the row identified by [id] with [dto]'s field values.
  ///
  /// Throws an exception if the update operation fails.
  Future<YourRateEntryDto> updateRate(String id, YourRateEntryDto dto);
}
