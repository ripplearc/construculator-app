import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_search_data_source.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_search_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase-backed implementation of [ProjectSearchRepository].
///
/// Delegates all operations to [ProjectSearchDataSource] and maps any thrown
/// exceptions to typed [Failure] values so callers never have to catch.
class ProjectSearchRepositoryImpl implements ProjectSearchRepository {
  final ProjectSearchDataSource _dataSource;
  static final _logger = AppLogger().tag('ProjectSearchRepositoryImpl');

  /// Creates a [ProjectSearchRepositoryImpl] with the given [dataSource].
  ProjectSearchRepositoryImpl({required ProjectSearchDataSource dataSource})
    : _dataSource = dataSource;

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
        _logger.warning(
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
  Future<Either<Failure, List<Project>>> searchProjects({
    required String userId,
    required String query,
    DateTime? filterByDate,
    String? filterByTag,
    String? filterByOwner,
  }) async {
    if (query.trim().isEmpty || userId.trim().isEmpty) {
      return Right([]);
    }

    try {
      _logger.debug('Searching projects for query: $query');
      final dtos = await _dataSource.fetchProjectsBySearchQuery(
        userId: userId,
        query: query,
        filterByDate: filterByDate,
        filterByTag: filterByTag,
        filterByOwner: filterByOwner,
      );
      _logger.debug('Search completed: ${dtos.length} projects found');
      return Right(dtos.map((dto) => dto.toDomain()).toList());
    } catch (e) {
      return Left(_handleError(e, 'searching projects'));
    }
  }

  @override
  Future<Either<Failure, void>> saveRecentProjectSearch({
    required String userId,
    required String searchTerm,
    bool hasResults = false,
  }) async {
    if (userId.trim().isEmpty || searchTerm.trim().isEmpty) {
      return Right(null);
    }

    try {
      _logger.debug(
        'Saving recent project search: $searchTerm, hasResults: $hasResults',
      );
      await _dataSource.saveRecentProjectSearch(
        userId: userId,
        searchTerm: searchTerm,
        hasResults: hasResults,
      );
      return Right(null);
    } catch (e) {
      return Left(_handleError(e, 'saving recent project search'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getRecentProjectSearches({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      return Right([]);
    }

    try {
      _logger.debug('Fetching recent project searches for userId: $userId');
      final terms = await _dataSource.getRecentProjectSearches(userId: userId);
      _logger.debug('Fetched ${terms.length} recent project searches');
      return Right(terms);
    } catch (e) {
      return Left(_handleError(e, 'fetching recent project searches'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecentProjectSearch({
    required String userId,
    required String searchTerm,
  }) async {
    if (userId.trim().isEmpty || searchTerm.trim().isEmpty) {
      return Right(null);
    }

    try {
      _logger.debug('Deleting recent project search: $searchTerm');
      await _dataSource.deleteRecentProjectSearch(
        userId: userId,
        searchTerm: searchTerm,
      );
      return Right(null);
    } catch (e) {
      return Left(_handleError(e, 'deleting recent project search'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getProjectSearchSuggestions({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      return Right([]);
    }

    try {
      _logger.debug('Fetching project search suggestions for userId: $userId');
      final suggestions = await _dataSource.getProjectSearchSuggestions(
        userId: userId,
      );
      _logger.debug('Fetched ${suggestions.length} project search suggestions');
      return Right(suggestions);
    } catch (e) {
      return Left(_handleError(e, 'fetching project search suggestions'));
    }
  }
}
