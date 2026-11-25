import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:powersync/powersync.dart';

/// Lifecycle state of the sync connection.
enum _SyncState {
  /// No sync connection, and no synced rows left in local SQLite.
  disconnected,

  /// A sync connection is established.
  connected,

  /// The connection is down, but the previous user's synced rows are still in
  /// local SQLite and must be cleared before any new connection.
  clearPending,
}

/// Default [PowerSyncManager]. It connects, disconnects and clears only when
/// its caller says so, and never listens to Supabase events, because a
/// connection made before the sign-in check could sync one user's rows under
/// another user's session.
class PowerSyncManagerImpl implements PowerSyncManager {
  final PowerSyncDatabase _database;
  final PowerSyncBackendConnector _connector;
  final _logger = AppLogger().tag('PowerSyncManager');

  _SyncState _state = _SyncState.disconnected;

  // Tail of the lifecycle operation chain. Every [connect] and
  // [disconnectAndClear] is appended to it, so the two can never interleave
  // and observe each other's half-applied state.
  Future<void> _operations = Future<void>.value();

  PowerSyncManagerImpl({required this._database, required this._connector});

  @override
  PowerSyncDatabase get database => _database;

  // Appends the action to the lifecycle chain and returns the future for that
  // link, so callers await their own operation rather than the whole queue.
  Future<void> _serialize(Future<void> Function() action) {
    final next = _operations.then((_) => action());
    // The stored tail swallows failures so one bad operation cannot poison
    // every later link in the chain. The caller still sees the error through
    // the future returned here.
    _operations = next.catchError((_) {});
    return next;
  }

  @override
  Future<void> connect() => _serialize(_connect);

  @override
  Future<void> disconnectKeepingData() => _serialize(_disconnectKeepingData);

  @override
  Future<void> disconnectAndClear() => _serialize(_disconnectAndClear);

  @override
  Future<void> disconnectAndClearOrThrow() => _serialize(_clearOrThrow);

  Future<void> _connect() async {
    if (_state == _SyncState.clearPending) {
      await _disconnectAndClear();
      if (_state == _SyncState.clearPending) {
        throw StateError('PowerSync did not connect: a clear is still pending');
      }
    }
    if (_state == _SyncState.connected) {
      return;
    }
    _logger.info('Starting PowerSync sync connection');
    try {
      await _database.connect(connector: _connector);
      _state = _SyncState.connected;
    } catch (error, stackTrace) {
      _logger.warning('Failed to start PowerSync sync', error, stackTrace);
      rethrow;
    }
  }

  Future<void> _disconnectKeepingData() async {
    if (_state != _SyncState.connected) {
      return;
    }
    await _database.disconnect();
    _state = _SyncState.clearPending;
  }

  Future<void> _disconnectAndClear() async {
    if (_state == _SyncState.disconnected) {
      return;
    }
    try {
      await _clearOrThrow();
    } catch (_) {
      // Already logged by _clearOrThrow, and clearPending makes the next
      // connect retry the clear.
    }
  }

  Future<void> _clearOrThrow() async {
    // Local-only tables hold data PowerSync does not own (the kept company
    // id), so their owners clear them and this call must not race them.
    _logger.info('Disconnecting PowerSync and clearing local synced data');
    try {
      await _database.disconnectAndClear(clearLocal: false);
      _state = _SyncState.disconnected;
    } catch (error, stackTrace) {
      // Stay in clearPending so the next connect retries the clear before
      // letting a new session sync on top of the old rows.
      _state = _SyncState.clearPending;
      _logger.error(
        'Failed to disconnect and clear PowerSync',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
