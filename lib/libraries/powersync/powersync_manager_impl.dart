import 'dart:async';

import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Lifecycle state of the sync connection.
enum _SyncState {
  /// No sync connection, and no synced rows left in local SQLite.
  disconnected,

  /// A sync connection is established.
  connected,

  /// A clear was attempted and failed. The connection is down, but the
  /// previous user's synced rows are still in local SQLite and must be
  /// cleared before any new connection is established.
  clearPending,
}

/// Default [PowerSyncManager] that drives the sync connection from Supabase
/// authentication events.
///
/// On construction it subscribes to [SupabaseWrapper.onAuthStateChange] and,
/// if a session has already been restored (e.g. on app relaunch), connects
/// immediately. It then [connect]s on sign-in and [disconnectAndClear]s on
/// sign-out. Token refreshes and other auth events are ignored — the connector
/// refreshes credentials on demand, so an active connection survives them.
///
/// Listens to the raw Supabase stream rather than the app's own
/// `AuthNotifier`, which is otherwise the standard way to observe auth state.
/// `AuthNotifier` is fed exclusively by `AuthManagerImpl`, which is registered
/// as a *lazy* singleton — until something resolves `AuthManager`, nothing
/// emits on that stream, so a manager listening to it would never connect. Its
/// controller is also a plain (non-replay) broadcast, so an `AuthManager`
/// resolved before this manager subscribes would drop its initial state
/// instead of buffering it. Both hazards disappear only if `AuthManager`
/// becomes an eager singleton with a replayed initial state; until then the
/// raw stream is the sole source that is correct at module-commit time.
class PowerSyncManagerImpl implements PowerSyncManager, Disposable {
  final PowerSyncDatabase _database;
  final PowerSyncBackendConnector _connector;
  final SupabaseWrapper _supabaseWrapper;
  final _logger = AppLogger().tag('PowerSyncManager');

  StreamSubscription<supabase.AuthState>? _authSubscription;

  _SyncState _state = _SyncState.disconnected;

  // Tail of the lifecycle operation chain. Every [connect] and
  // [disconnectAndClear] is appended to it, so the two can never interleave
  // and observe each other's half-applied state.
  Future<void> _operations = Future<void>.value();

  PowerSyncManagerImpl({
    required this._database,
    required this._connector,
    required this._supabaseWrapper,
  }) {
    _initAuthListener();
  }

  @override
  PowerSyncDatabase get database => _database;

  /// Completes once every lifecycle operation queued so far has finished.
  ///
  /// The auth listener starts operations with [unawaited], so a test driving
  /// the manager through auth events has no future of its own to await. This
  /// exposes the chain's tail as a deterministic settle point, avoiding any
  /// need to drain the real event loop.
  @visibleForTesting
  Future<void> get pendingOperations => _operations;

  void _initAuthListener() {
    _authSubscription = _supabaseWrapper.onAuthStateChange.listen(
      (state) {
        switch (state.event) {
          case supabase.AuthChangeEvent.signedIn:
          case supabase.AuthChangeEvent.initialSession:
            if (state.session != null) {
              unawaited(connect());
            }
          case supabase.AuthChangeEvent.signedOut:
            unawaited(disconnectAndClear());
          default:
            break;
        }
      },
      onError: (error) {
        _logger.warning('Error in auth state stream, ignoring', error);
      },
    );

    if (_supabaseWrapper.isAuthenticated) {
      unawaited(connect());
    }
  }

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
  Future<void> disconnectAndClear() => _serialize(_disconnectAndClear);

  Future<void> _connect() async {
    if (_state == _SyncState.clearPending) {
      await _disconnectAndClear();
      if (_state == _SyncState.clearPending) {
        _logger.warning(
          'Skipping PowerSync connect: local synced data from the previous '
          'session could not be cleared',
        );
        return;
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
    }
  }

  Future<void> _disconnectAndClear() async {
    if (_state == _SyncState.disconnected) {
      return;
    }
    _logger.info('Disconnecting PowerSync and clearing local synced data');
    try {
      await _database.disconnectAndClear();
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
    }
  }

  @override
  void dispose() {
    final subscription = _authSubscription;
    _authSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
  }
}
