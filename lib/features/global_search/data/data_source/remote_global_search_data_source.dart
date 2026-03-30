import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/global_search/data/data_source/interfaces/global_search_data_source.dart';
import 'package:construculator/features/global_search/data/models/search_params.dart';
import 'package:construculator/features/global_search/data/models/search_results_dto.dart';
import 'package:construculator/features/global_search/data/models/search_scope.dart';
import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Remote implementation of [GlobalSearchDataSource] using Supabase.
///
/// Executes full-text search via the `global_search` RPC and manages per-user
/// search history in the `search_history` table. All history operations fail
/// silently when no user is authenticated.
class RemoteGlobalSearchDataSource implements GlobalSearchDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('RemoteGlobalSearchDataSource');

  const RemoteGlobalSearchDataSource({required SupabaseWrapper supabaseWrapper})
    : _supabaseWrapper = supabaseWrapper;

  @override
  Future<SearchResultsDto> search(SearchParams params) async {
    try {
      _logger.debug('Performing global search for query: ${params.query}');

      final rpcParams = _toRpcParams(params);
      final response = await _supabaseWrapper.rpc<Map<String, dynamic>>(
        DatabaseConstants.globalSearchRpcFunction,
        params: rpcParams,
      );

      return _parseSearchResponse(response);
    } catch (error, stackTrace) {
      _logger.error(
        'Error while performing global search for query: ${params.query}, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> getRecentSearches(SearchScope scope) async {
    try {
      final userId = _supabaseWrapper.currentUser?.id;
      if (userId == null) {
        _logger.debug('No user logged in, returning empty recent searches');
        return [];
      }

      _logger.debug('Getting recent searches for scope: ${scope.name}');

      final rows = await _supabaseWrapper.selectMatch(
        table: DatabaseConstants.searchHistoryTable,
        filters: {
          DatabaseConstants.userIdColumn: userId,
          DatabaseConstants.scopeColumn: scope.name,
        },
        orderBy: DatabaseConstants.createdAtColumn,
        ascending: false,
      );

      return rows
          .map(
            (row) => row[DatabaseConstants.searchTermColumn]?.toString() ?? '',
          )
          .where((term) => term.isNotEmpty)
          .toList();
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting recent searches for scope: ${scope.name}, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<void> saveRecentSearch(
    String searchTerm,
    SearchScope scope, {
    String? projectId,
    bool hasResults = false,
  }) async {
    try {
      final normalized = searchTerm.toLowerCase().trim();
      if (normalized.isEmpty) return;

      final userId = _supabaseWrapper.currentUser?.id;
      if (userId == null) {
        _logger.debug('No user logged in, skipping save recent search');
        return;
      }

      _logger.debug(
        'Saving recent search: $normalized for scope: ${scope.name}, '
        'projectId: $projectId, hasResults: $hasResults',
      );

      await _supabaseWrapper.upsert(
        table: DatabaseConstants.searchHistoryTable,
        data: {
          DatabaseConstants.userIdColumn: userId,
          DatabaseConstants.searchTermColumn: normalized,
          DatabaseConstants.scopeColumn: scope.name,
          DatabaseConstants.projectIdColumn: projectId,
          DatabaseConstants.hasResultsColumn: hasResults,
          // search_count intentionally omitted — incremented atomically by DB trigger on conflict.
          // created_at intentionally omitted — DB DEFAULT handles insert;
          // trigger preserves OLD.created_at on conflict update.
        },
        onConflict: DatabaseConstants.searchHistoryUpsertConflictColumns,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Error while saving recent search: $searchTerm, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteRecentSearch(String searchTerm, SearchScope scope) async {
    try {
      final normalized = searchTerm.toLowerCase().trim();
      if (normalized.isEmpty) return;

      final userId = _supabaseWrapper.currentUser?.id;
      if (userId == null) {
        _logger.debug('No user logged in, skipping delete recent search');
        return;
      }

      _logger.debug(
        'Deleting recent search: $normalized for scope: ${scope.name}',
      );

      await _supabaseWrapper.deleteMatch(
        table: DatabaseConstants.searchHistoryTable,
        filters: {
          DatabaseConstants.userIdColumn: userId,
          DatabaseConstants.scopeColumn: scope.name,
          DatabaseConstants.searchTermColumn: normalized,
        },
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Error while deleting recent search: $searchTerm, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> getSearchSuggestions() async {
    try {
      _logger.debug('Fetching search suggestions');
      final userId = _supabaseWrapper.currentUser?.id;
      if (userId == null) {
        _logger.debug('No user logged in, returning empty search suggestions');
        return [];
      }
      final response = await _supabaseWrapper.rpc<List<dynamic>>(
        DatabaseConstants.searchSuggestionsRpcFunction,
        params: {DatabaseConstants.userIdColumn: userId},
      );
      return response.whereType<String>().toList();
    } catch (error, stackTrace) {
      _logger.error(
        'Error fetching search suggestions, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  Map<String, dynamic> _toRpcParams(SearchParams params) {
    return {
      'query': params.query,
      'filter_by_tag': params.filterByTag,
      'filter_by_date': params.filterByDate?.toIso8601String(),
      'filter_by_owner': params.filterByOwner,
      'scope': params.scope?.name,
      'offset': params.pagination.offset,
      'limit': params.pagination.limit,
    };
  }

  SearchResultsDto _parseSearchResponse(Map<String, dynamic> response) {
    final projectsRaw = response['projects'] as List<dynamic>? ?? [];
    final estimationsRaw = response['estimations'] as List<dynamic>? ?? [];
    final membersRaw = response['members'] as List<dynamic>? ?? [];

    final projects = projectsRaw
        .whereType<Map<String, dynamic>>()
        .map(ProjectDto.fromJson)
        .toList();

    final estimations = estimationsRaw
        .whereType<Map<String, dynamic>>()
        .map(CostEstimateDto.fromJson)
        .toList();

    final members = membersRaw
        .whereType<Map<String, dynamic>>()
        .map(UserProfileDto.fromJson)
        .toList();

    return SearchResultsDto(
      projects: projects,
      estimations: estimations,
      members: members,
    );
  }
}
