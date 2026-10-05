import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Remote data source for "Your rates" operations using Supabase.
///
/// This data source handles all remote database operations for the
/// contractor's personal saved-rate book. The optional `companyId` filter on
/// [fetchRates] is what actually scopes a read to one company for a caller
/// who belongs to more than one — RLS alone does not (be#57's README
/// documents the same split on the backend side of this table).
class RemoteYourRatesDataSource implements YourRatesDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteYourRatesDataSource');

  RemoteYourRatesDataSource({required this._supabaseWrapper});

  @override
  Future<List<YourRateEntryDto>> fetchRates({
    String? category,
    String? companyId,
    int? limit,
  }) async {
    _logger.debug(
      'Fetching your rates'
      '${category != null ? ', category: $category' : ''}',
    );

    final filters = <String, dynamic>{
      DatabaseConstants.categoryColumn: ?category,
      DatabaseConstants.companyIdColumn: ?companyId,
    };

    // No server-side text search primitive is available on SupabaseWrapper
    // (no ilike-style filter option); item-name substring filtering happens
    // client-side in the repository against this unfiltered-by-name result.
    // Acceptable for a personal rate book's expected row counts, but would
    // not scale to a large shared catalog.
    final response = await _supabaseWrapper.selectMatch(
      table: DatabaseConstants.yourRatesTable,
      filters: filters,
      orderBy: DatabaseConstants.savedAtColumn,
      ascending: false,
      limit: limit,
    );

    return response.map(YourRateEntryDto.fromJson).toList();
  }

  @override
  Future<YourRateEntryDto> insertRate(YourRateEntryDto dto) async {
    _logger.debug('Inserting your rate: ${dto.itemName}');
    final response = await _supabaseWrapper.insert(
      table: DatabaseConstants.yourRatesTable,
      data: dto.toJson(),
    );
    return YourRateEntryDto.fromJson(response);
  }

  @override
  Future<YourRateEntryDto> updateRate(String id, YourRateEntryDto dto) async {
    _logger.debug('Updating your rate: $id');
    final response = await _supabaseWrapper.update(
      table: DatabaseConstants.yourRatesTable,
      data: dto.toJson(),
      filterColumn: DatabaseConstants.idColumn,
      filterValue: id,
    );
    return YourRateEntryDto.fromJson(response);
  }
}
