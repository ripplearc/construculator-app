import 'dart:async';
import 'dart:io';

import 'package:construculator/features/global_search/data/data_source/interfaces/global_search_data_source.dart';
import 'package:construculator/features/global_search/data/models/search_params.dart';
import 'package:construculator/features/global_search/data/models/search_scope.dart';
import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase-backed implementation of [GlobalSearchRepository].
///
/// Delegates all operations to [GlobalSearchDataSource] and maps any thrown
/// exceptions to typed [Failure] values so callers never have to catch.
class GlobalSearchRepositoryImpl implements GlobalSearchRepository {
  final GlobalSearchDataSource _dataSource;
  static final _logger = AppLogger().tag('GlobalSearchRepositoryImpl');

  GlobalSearchRepositoryImpl({required GlobalSearchDataSource dataSource})
    : _dataSource = dataSource;

  SearchScope _toDataScope(SearchScopeEntity entity) =>
      SearchScope.values.byName(entity.name);

  SearchParams _toDataParams(SearchParamsEntity entity) {
    final entityScope = entity.scope;
    return SearchParams(
      query: entity.query,
      filterByTag: entity.filterByTag,
      filterByDate: entity.filterByDate,
      filterByOwner: entity.filterByOwner,
      scope: entityScope != null ? _toDataScope(entityScope) : null,
      pagination: entity.pagination,
    );
  }

  Failure _handleError(Object error, String operation) {
    if (error is TimeoutException) {
      _logger.warning(
        'Timeout error $operation: '
        'message=${error.message}, duration=${error.duration}',
      );
      return SearchFailure(errorType: SearchErrorType.timeoutError);
    }

    if (error is SocketException) {
      _logger.warning(
        'Connection error $operation: '
        'message=${error.message}, address=${error.address}, '
        'port=${error.port}, osError=${error.osError}',
      );
      return SearchFailure(errorType: SearchErrorType.connectionError);
    }

    if (error is TypeError) {
      _logger.error(
        'Parsing error $operation: ${error.toString()}',
        'returning parsing failure',
      );
      return SearchFailure(errorType: SearchErrorType.parsingError);
    }

    if (error is supabase.PostgrestException) {
      final postgresErrorCode = PostgresErrorCode.fromCode(error.code);

      if (postgresErrorCode == PostgresErrorCode.noDataFound) {
        _logger.warning(
          'No data found $operation: '
          'code=${error.code}, message=${error.message}',
        );
        return SearchFailure(errorType: SearchErrorType.notFoundError);
      }

      if (postgresErrorCode == PostgresErrorCode.connectionFailure ||
          postgresErrorCode == PostgresErrorCode.unableToConnect ||
          postgresErrorCode == PostgresErrorCode.connectionDoesNotExist) {
        _logger.error(
          'PostgreSQL connection error $operation: '
          'code=${error.code}, message=${error.message}, '
          'details=${error.details}, hint=${error.hint}',
        );
        return SearchFailure(errorType: SearchErrorType.connectionError);
      }

      _logger.error(
        'Unexpected PostgreSQL error $operation: '
        'code=${error.code}, message=${error.message}, '
        'details=${error.details}, hint=${error.hint}',
      );
      return SearchFailure(errorType: SearchErrorType.unexpectedDatabaseError);
    }

    _logger.error('Unexpected error $operation: $error');
    return UnexpectedFailure();
  }

  @override
  Future<Either<Failure, SearchResults>> search(SearchParamsEntity params) async {
    try {
      _logger.debug('Performing global search for query: ${params.query}');
      final dto = await _dataSource.search(_toDataParams(params));
      _logger.debug(
        'Search completed: ${dto.projects.length} projects, '
        '${dto.estimations.length} estimations, '
        '${dto.members.length} members',
      );
      return Right(dto.toDomain());
    } catch (e) {
      return Left(_handleError(e, 'performing global search'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getRecentSearches(
    SearchScopeEntity scope,
  ) async {
    try {
      _logger.debug('Getting recent searches for scope: ${scope.name}');
      final terms = await _dataSource.getRecentSearches(_toDataScope(scope));
      _logger.debug('Retrieved ${terms.length} recent searches');
      return Right(terms);
    } catch (e) {
      return Left(_handleError(e, 'getting recent searches'));
    }
  }

  @override
  Future<Either<Failure, void>> saveRecentSearch(
    String searchTerm,
    SearchScopeEntity scope, {
    String? projectId,
    bool hasResults = false,
  }) async {
    try {
      _logger.debug(
        'Saving recent search: $searchTerm for scope: ${scope.name}',
      );
      await _dataSource.saveRecentSearch(
        searchTerm,
        _toDataScope(scope),
        projectId: projectId,
        hasResults: hasResults,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'saving recent search'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecentSearch(
    String searchTerm,
    SearchScopeEntity scope,
  ) async {
    try {
      _logger.debug(
        'Deleting recent search: $searchTerm for scope: ${scope.name}',
      );
      await _dataSource.deleteRecentSearch(searchTerm, _toDataScope(scope));
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'deleting recent search'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSearchSuggestions() async {
    try {
      _logger.debug('Fetching search suggestions');
      final suggestions = await _dataSource.getSearchSuggestions();
      _logger.debug('Retrieved ${suggestions.length} search suggestions');
      return Right(suggestions);
    } catch (e) {
      return Left(_handleError(e, 'fetching search suggestions'));
    }
  }
}
