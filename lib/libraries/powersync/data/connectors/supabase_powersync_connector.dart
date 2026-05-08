import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Connector that integrates PowerSync with Supabase backend.
///
/// Responsibilities:
/// - Provides JWT credentials to PowerSync for authentication
/// - Uploads local mutations to Supabase with proper error handling
/// - Distinguishes permanent failures (RLS denial) from transient failures
class SupabasePowerSyncConnector extends PowerSyncBackendConnector {
  final SupabaseWrapper _supabaseWrapper;
  final EnvLoader _envLoader;
  static final _logger = AppLogger().tag('SupabasePowerSyncConnector');

  SupabasePowerSyncConnector({
    required SupabaseWrapper supabaseWrapper,
    required EnvLoader envLoader,
  })  : _supabaseWrapper = supabaseWrapper,
        _envLoader = envLoader;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    _logger.debug('Fetching PowerSync credentials');

    final powerSyncUrl = _envLoader.get('POWERSYNC_URL');
    if (powerSyncUrl == null || powerSyncUrl.isEmpty) {
      _logger.error(
        'POWERSYNC_URL environment variable is not set',
      );
      return null;
    }

    if (!_supabaseWrapper.isAuthenticated) {
      _logger.warning('User is not authenticated, cannot fetch credentials');
      return null;
    }

    try {
      await _supabaseWrapper.refreshSession();
      _logger.debug('Session refreshed successfully');
    } catch (error) {
      _logger.warning('Failed to refresh session: $error');
      return null;
    }

    final session = _supabaseWrapper.currentSession;
    if (session == null) {
      _logger.warning('No active session found after refresh');
      return null;
    }

    _logger.debug('Successfully fetched PowerSync credentials');
    return PowerSyncCredentials(
      endpoint: powerSyncUrl,
      token: session.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    _logger.debug(
      'Processing CRUD transaction with ${transaction.crud.length} operations',
    );

    try {
      for (final operation in transaction.crud) {
        await _processOperation(operation);
      }

      await transaction.complete();
      _logger.debug('Transaction completed successfully');
    } catch (error) {
      await _handleUploadError(error, transaction);
    }
  }

  Future<void> _processOperation(CrudEntry operation) async {
    _logger.debug(
      'Processing ${operation.op} operation on table ${operation.table}',
    );

    switch (operation.op) {
      case UpdateType.put:
        final putData = operation.opData;
        if (putData == null) {
          throw StateError(
            'opData is null for PUT operation on table ${operation.table}',
          );
        }
        await _supabaseWrapper.upsert(
          table: operation.table,
          data: putData,
          onConflict: 'id',
        );
      case UpdateType.patch:
        final patchData = operation.opData;
        if (patchData == null) {
          throw StateError(
            'opData is null for PATCH operation on table ${operation.table}',
          );
        }
        await _supabaseWrapper.update(
          table: operation.table,
          data: patchData,
          filterColumn: 'id',
          filterValue: operation.id,
        );
      case UpdateType.delete:
        await _supabaseWrapper.delete(
          table: operation.table,
          filterColumn: 'id',
          filterValue: operation.id,
        );
    }
  }

  Future<void> _handleUploadError(
    Object error,
    CrudTransaction transaction,
  ) async {
    if (error is supabase.PostgrestException && error.code == '42501') {
      _logger.warning(
        'RLS denial detected (code 42501): ${error.message}. '
        'Marking transaction as complete to unblock upload queue.',
      );

      await transaction.complete();

      // TODO: [CA-660] Emit conflict event to UI layer when RLS denial is detected.
      // https://ripplearc.youtrack.cloud/issue/CA-660
      // The local optimistic change persists in SQLite, but was rejected by the server.
      // Users should be notified via a conflict notification UI.
      return;
    }

    _logger.error(
      'Transient error during upload: $error. '
      'PowerSync will retry automatically.',
    );
    throw error;
  }
}
