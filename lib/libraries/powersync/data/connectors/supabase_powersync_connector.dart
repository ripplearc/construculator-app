import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Connector that integrates PowerSync with Supabase backend.
///
/// Responsibilities:
/// - Provides JWT credentials to PowerSync for authentication
/// - Uploads local mutations to Supabase with proper error handling
/// - Distinguishes permanent failures (RLS denial) from transient failures
///
/// A refused `your_rates` change is skipped so it cannot block the queue:
/// a value the server rejects (23514), a duplicate from another phone (23505),
/// and a PATCH whose row the server does not have (PGRST116).
///
/// When two phones save the same Your rates entry, the later upload overwrites
/// the earlier one. Two entries are the same when the item name, pricing
/// method and label match, where a name or label matches ignoring capital
/// letters and extra spaces. That copies the server rule behind the
/// `item_name_key` column: trim, collapse runs of spaces to one, lower-case.
/// If the server rule changes, change `YourRateRefusalKey.normalizeName` with it.
class SupabasePowerSyncConnector extends PowerSyncBackendConnector {
  final SupabaseWrapper _supabaseWrapper;
  final EnvLoader _envLoader;
  static final _logger = AppLogger().tag('SupabasePowerSyncConnector');

  /// Creates a connector for syncing PowerSync with Supabase.
  SupabasePowerSyncConnector({
    required this._supabaseWrapper,
    required this._envLoader,
  });

  /// Fetches the current PowerSync credentials from Supabase.
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    _logger.debug('Fetching PowerSync credentials');

    final powerSyncUrl = _envLoader.get('POWERSYNC_URL');
    if (powerSyncUrl == null || powerSyncUrl.isEmpty) {
      _logger.error('POWERSYNC_URL environment variable is not set');
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

  /// Uploads queued local mutations to Supabase.
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
        await _processOperationUnlessRefused(database, operation);
      }

      await transaction.complete();
      _logger.debug('Transaction completed successfully');
    } catch (error) {
      await _handleUploadError(error, transaction);
    }
  }

  Future<void> _processOperationUnlessRefused(
    PowerSyncDatabase database,
    CrudEntry operation,
  ) async {
    try {
      await _processOperation(operation);
      await _forgetRefusalWithoutBlocking(database, operation);
    } on supabase.PostgrestException catch (error) {
      if (!_isRefusedRateChange(error, operation)) rethrow;
      // TODO: [CA-1306] Derive the rate id from its name and label so a clash is one row and later edits find it.
      // https://ripplearc.youtrack.cloud/issue/CA-1306
      if (await _overwroteRateWithSameKey(error, operation)) {
        await _forgetRefusalWithoutBlocking(database, operation);
        return;
      }
      _logger.warning(
        'The server refused a your_rates change (code ${error.code}): '
        '${error.message}. Skipping it so the queue is not blocked.',
      );
      await _recordRefusalWithoutBlocking(database, operation);
    }
  }

  Future<void> _recordRefusalWithoutBlocking(
    PowerSyncDatabase database,
    CrudEntry operation,
  ) async {
    try {
      await _recordRefusal(database, operation);
    } catch (error, stackTrace) {
      _logger.error(
        'Could not record the refused your_rates change; '
        'the user will not be told it was not kept',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _forgetRefusalWithoutBlocking(
    PowerSyncDatabase database,
    CrudEntry operation,
  ) async {
    try {
      await _forgetRefusal(database, operation);
    } catch (error, stackTrace) {
      _logger.error(
        'Could not forget the refusal of an accepted your_rates change; '
        'the form may still say the price was not kept',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _forgetRefusal(
    PowerSyncDatabase database,
    CrudEntry operation,
  ) async {
    if (operation.table != DatabaseConstants.yourRatesTable) return;
    if (operation.op == UpdateType.delete) return;
    if (_refusedRateAmount(operation) == null) return;
    final item = await _phoneRateOf(database, operation);
    if (item == null) return;
    await database.execute(
      'DELETE FROM ${DatabaseConstants.yourRateRefusalsTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?',
      [_refusalKeyOf(item)],
    );
  }

  Future<Map<String, dynamic>?> _phoneRateOf(
    PowerSyncDatabase database,
    CrudEntry operation,
  ) async {
    final row = await database.getOptional(
      'SELECT * FROM ${DatabaseConstants.yourRatesTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?',
      [operation.id],
    );
    return row == null ? null : Map<String, dynamic>.of(row);
  }

  String _refusalKeyOf(Map<String, dynamic> rate) => YourRateRefusalKey.of(
    companyId: rate[DatabaseConstants.companyIdColumn] as String,
    category: rate[DatabaseConstants.categoryColumn] as String,
    itemName: rate[DatabaseConstants.itemNameColumn] as String,
    equipmentMethod: rate[DatabaseConstants.equipmentMethodColumn] as String?,
  );

  Future<void> _recordRefusal(
    PowerSyncDatabase database,
    CrudEntry operation,
  ) async {
    final refusedAmount = _refusedRateAmount(operation);
    if (refusedAmount == null) return;
    final item = await _phoneRateOf(database, operation);
    if (item == null) return;

    await database.execute(
      'INSERT OR REPLACE INTO ${DatabaseConstants.yourRateRefusalsTable} '
      '(${DatabaseConstants.idColumn}, ${DatabaseConstants.companyIdColumn}, '
      '${DatabaseConstants.categoryColumn}, '
      '${DatabaseConstants.refusedRowIdColumn}, '
      '${DatabaseConstants.itemNameColumn}, '
      '${DatabaseConstants.equipmentMethodColumn}, '
      '${DatabaseConstants.entryLabelColumn}, '
      '${DatabaseConstants.refusedAmountColumn}, '
      '${DatabaseConstants.acceptedAmountColumn}, '
      '${DatabaseConstants.shownAtColumn}) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)',
      [
        _refusalKeyOf(item),
        item[DatabaseConstants.companyIdColumn],
        item[DatabaseConstants.categoryColumn],
        operation.id,
        item[DatabaseConstants.itemNameColumn],
        item[DatabaseConstants.equipmentMethodColumn],
        item[DatabaseConstants.entryLabelColumn],
        refusedAmount,
        await _lastAcceptedAmountOrNull(operation, item),
      ],
    );
  }

  double? _refusedRateAmount(CrudEntry operation) =>
      (operation.opData?[DatabaseConstants.rateAmountColumn] as num?)
          ?.toDouble();

  // The accepted row is found by what the item is, not by the refused row's
  // id: a refused insert has an id the server never saw.
  Future<double?> _lastAcceptedAmountOrNull(
    CrudEntry operation,
    Map<String, dynamic> item,
  ) async {
    try {
      final rows = await _supabaseWrapper.selectMatch(
        table: operation.table,
        filters: {
          DatabaseConstants.companyIdColumn:
              item[DatabaseConstants.companyIdColumn],
          DatabaseConstants.categoryColumn:
              item[DatabaseConstants.categoryColumn],
        },
      );
      final accepted = rows
          .where((row) => _hasSameRateKey(row, item))
          .firstOrNull;
      return (accepted?[DatabaseConstants.rateAmountColumn] as num?)
          ?.toDouble();
    } catch (error) {
      _logger.warning('Could not read the last accepted price: $error');
      return null;
    }
  }

  Future<bool> _overwroteRateWithSameKey(
    supabase.PostgrestException error,
    CrudEntry operation,
  ) async {
    final rate = operation.opData;
    if (operation.op != UpdateType.put || rate == null) return false;
    if (PostgresErrorCode.fromCode(error.code) !=
        PostgresErrorCode.uniqueViolation) {
      return false;
    }

    final saved = await _supabaseWrapper.selectMatch(
      table: operation.table,
      filters: {
        DatabaseConstants.companyIdColumn:
            rate[DatabaseConstants.companyIdColumn],
        DatabaseConstants.categoryColumn:
            rate[DatabaseConstants.categoryColumn],
      },
    );
    final sameKey = saved
        .where((row) => _hasSameRateKey(row, rate))
        .firstOrNull;
    if (sameKey == null) return false;

    _logger.info(
      'Another phone saved this your_rates entry first; '
      'this change overwrites it, so the last change received wins',
    );
    await _supabaseWrapper.update(
      table: operation.table,
      data: rate,
      filterColumn: DatabaseConstants.idColumn,
      filterValue: sameKey[DatabaseConstants.idColumn],
    );
    return true;
  }

  bool _hasSameRateKey(Map<String, dynamic> saved, Map<String, dynamic> rate) {
    return _rateKey(saved[DatabaseConstants.itemNameColumn]) ==
            _rateKey(rate[DatabaseConstants.itemNameColumn]) &&
        saved[DatabaseConstants.equipmentMethodColumn] ==
            rate[DatabaseConstants.equipmentMethodColumn] &&
        _rateKey(saved[DatabaseConstants.entryLabelColumn]) ==
            _rateKey(rate[DatabaseConstants.entryLabelColumn]);
  }

  String? _rateKey(Object? text) {
    final key = text == null
        ? null
        : YourRateRefusalKey.normalizeName(text as String);
    return (key == null || key.isEmpty) ? null : key;
  }

  bool _isRefusedRateChange(
    supabase.PostgrestException error,
    CrudEntry operation,
  ) {
    if (operation.table != DatabaseConstants.yourRatesTable) return false;
    final code = PostgresErrorCode.fromCode(error.code);
    return code == PostgresErrorCode.checkViolation ||
        code == PostgresErrorCode.uniqueViolation ||
        code == PostgresErrorCode.rlsViolation ||
        (operation.op == UpdateType.patch &&
            code == PostgresErrorCode.noDataFound);
  }

  // Applies a single local CRUD operation to the corresponding Supabase table,
  // mapping the PowerSync UpdateType to an upsert, update, or delete. Throws a
  // StateError if opData is missing for a put or patch.
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
          data: {...putData, 'id': operation.id},
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

  // Handles a failed upload transaction. A permanent RLS denial (Postgres code
  // 42501) is non-retryable, so the transaction is completed to unblock the
  // upload queue. Any other error is treated as transient and rethrown so
  // PowerSync retries the transaction automatically.
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
