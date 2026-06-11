import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/tag/data/data_source/interfaces/tag_data_source.dart';
import 'package:construculator/libraries/tag/domain/entities/tag_entity.dart';
import 'package:construculator/libraries/tag/domain/repositories/tag_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase-backed implementation of [TagRepository].
///
/// Delegates all operations to [TagDataSource] and maps any thrown
/// exceptions to typed [Failure] values so callers never have to catch.
/// Tags are consumed by search filter UIs, so errors are mapped to
/// [SearchFailure] with a [SearchErrorType] consistent with the rest of
/// the search domain.
class TagRepositoryImpl implements TagRepository {
  final TagDataSource _dataSource;
  static final _logger = AppLogger().tag('TagRepositoryImpl');

  /// Creates a [TagRepositoryImpl].
  TagRepositoryImpl({required TagDataSource dataSource})
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
      return SearchFailure(
        errorType: SearchErrorType.unexpectedDatabaseError,
      );
    }

    _logger.error('Unexpected error $operation: $error');
    return UnexpectedFailure();
  }

  @override
  Future<Either<Failure, List<Tag>>> getTags() async {
    try {
      _logger.debug('Fetching tags');
      final dtos = await _dataSource.getTags();
      return Right(dtos.map((dto) => dto.toDomain()).toList());
    } catch (error) {
      return Left(_handleError(error, 'fetching tags'));
    }
  }
}
