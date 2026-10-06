import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/company/data/data_source/interfaces/local_current_company_data_source.dart';
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
/// separate remote data-source layer sits in front of [SupabaseWrapper].
///
/// A non-null id is also kept on the device through a
/// [LocalCurrentCompanyDataSource], and read back from there when the RPC
/// cannot be reached, so a user who has signed in once still resolves with no
/// signal. The kept id answers only that one call: the next call asks the
/// backend again. A missing id is never kept.
///
/// PowerSync's own sign-out clear also empties the device table; the clear in
/// [clearCache] covers the case where that clear has not run.
class CurrentCompanyResolverImpl implements CurrentCompanyResolver {
  final SupabaseWrapper _supabaseWrapper;
  final LocalCurrentCompanyDataSource _localDataSource;
  static final _logger = AppLogger().tag('CurrentCompanyResolverImpl');

  bool _hasResolved = false;
  String? _cachedCompanyId;
  String? _cachedForUserId;
  Future<Either<Failure, String?>>? _inFlight;
  int _cacheGeneration = 0;

  /// Creates a [CurrentCompanyResolverImpl].
  CurrentCompanyResolverImpl({
    required this._supabaseWrapper,
    required this._localDataSource,
  });

  @override
  Future<Either<Failure, String?>> resolve() {
    if (_hasResolved && _cachedForUserId == _supabaseWrapper.currentUser?.id) {
      return Future.value(Right(_cachedCompanyId));
    }
    return _inFlight ??= _fetch(_cacheGeneration);
  }

  Future<Either<Failure, String?>> _fetch(int requestGeneration) async {
    final userId = _supabaseWrapper.currentUser?.id;
    try {
      _logger.debug('Resolving current company id');
      final companyId = await _supabaseWrapper.rpc<String?>(
        DatabaseConstants.getMyCompanyIdRpcFunction,
      );

      // A stale fetch (clearCache ran while this one was in flight) must
      // not overwrite a newer caller's session, and a null result (the
      // signup step hasn't run yet) must not be cached permanently, since
      // either can resolve to a real id later in the same session.
      if (requestGeneration == _cacheGeneration) {
        if (companyId != null) {
          _cachedCompanyId = companyId;
          _cachedForUserId = userId;
          _hasResolved = true;
        }
        await _keepOnDevice(userId: userId, companyId: companyId);
      }
      return Right(companyId);
    } catch (e) {
      final failure = _handleError(e);
      final storedCompanyId = await _readStoredCompanyId(
        userId: userId,
        failure: failure,
      );
      if (storedCompanyId != null) {
        return Right(storedCompanyId);
      }
      return Left(failure);
    } finally {
      if (requestGeneration == _cacheGeneration) {
        _inFlight = null;
      }
    }
  }

  Future<void> _keepOnDevice({
    required String? userId,
    required String? companyId,
  }) async {
    if (userId == null) return;
    try {
      if (companyId == null) {
        await _localDataSource.clearCompanyId();
      } else {
        await _localDataSource.saveCompanyId(
          userId: userId,
          companyId: companyId,
        );
      }
    } catch (_) {
      // The data source already logged it. The id was resolved; failing to
      // keep it only costs the offline fallback, so the caller still gets
      // its answer.
    }
  }

  Future<String?> _readStoredCompanyId({
    required String? userId,
    required Failure failure,
  }) async {
    final isUnreachable =
        failure is CompanyFailure &&
        (failure.errorType == CompanyErrorType.connectionError ||
            failure.errorType == CompanyErrorType.timeoutError);
    if (userId == null || !isUnreachable) return null;
    try {
      return await _localDataSource.loadCompanyId(userId);
    } catch (_) {
      // The data source already logged it; the caller still gets the
      // connection failure that sent it here.
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    _hasResolved = false;
    _cachedCompanyId = null;
    _cachedForUserId = null;
    _inFlight = null;
    _cacheGeneration++;
    try {
      await _localDataSource.clearCompanyId();
    } catch (_) {
      // The data source already logged it. The in-memory state above is
      // already reset, so the next user is not served the old id.
    }
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
