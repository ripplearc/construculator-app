import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/company/domain/types/company_error_type.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase-backed [CurrentCompanyResolver].
///
/// Calls the [DatabaseConstants.getMyCompanyIdRpcFunction] RPC (CA-710)
/// directly — there is exactly one caller-scoped value to fetch, so no
/// separate data-source layer sits in front of [SupabaseWrapper].
class CurrentCompanyResolverImpl implements CurrentCompanyResolver {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('CurrentCompanyResolverImpl');

  /// Whether a call has already resolved successfully this session.
  bool _hasResolved = false;

  /// The last resolved company id, or null for no `company_users` row.
  /// Only meaningful when [_hasResolved] is true.
  String? _cachedCompanyId;

  /// The in-flight RPC call, if one is already running — shared so two
  /// callers racing [resolve] before the first response lands don't each
  /// fire their own RPC call.
  Future<Either<Failure, String?>>? _inFlight;

  /// Creates a [CurrentCompanyResolverImpl].
  CurrentCompanyResolverImpl({required this._supabaseWrapper});

  @override
  Future<Either<Failure, String?>> resolve() {
    if (_hasResolved) {
      return Future.value(Right(_cachedCompanyId));
    }
    return _inFlight ??= _fetch();
  }

  Future<Either<Failure, String?>> _fetch() async {
    try {
      _logger.debug('Resolving current company id');
      final companyId = await _supabaseWrapper.rpc<String?>(
        DatabaseConstants.getMyCompanyIdRpcFunction,
      );

      _cachedCompanyId = companyId;
      _hasResolved = true;
      return Right(companyId);
    } catch (e) {
      return Left(_handleError(e));
    } finally {
      _inFlight = null;
    }
  }

  @override
  void clearCache() {
    _hasResolved = false;
    _cachedCompanyId = null;
  }

  Failure _handleError(Object error) {
    if (error is TimeoutException) {
      _logger.warning(
        'Timeout error resolving current company id: '
        'message=${error.message}, duration=${error.duration}',
      );
      return const CompanyFailure(errorType: CompanyErrorType.timeoutError);
    }

    if (error is SocketException) {
      _logger.warning(
        'Connection error resolving current company id: '
        'message=${error.message}',
      );
      return const CompanyFailure(errorType: CompanyErrorType.connectionError);
    }

    if (error is supabase.PostgrestException) {
      _logger.error(
        'PostgreSQL error resolving current company id: '
        'code=${error.code}, message=${error.message}',
      );
      return const CompanyFailure(
        errorType: CompanyErrorType.unexpectedDatabaseError,
      );
    }

    _logger.error('Unexpected error resolving current company id: $error');
    return const CompanyFailure(errorType: CompanyErrorType.unexpectedError);
  }
}
