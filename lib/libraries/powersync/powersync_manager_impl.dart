import 'dart:async';

import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Default [PowerSyncManager] that drives the sync connection from Supabase
/// authentication events.
///
/// On construction it subscribes to [SupabaseWrapper.onAuthStateChange] and,
/// if a session has already been restored (e.g. on app relaunch), connects
/// immediately. It then [connect]s on sign-in and [disconnectAndClear]s on
/// sign-out. Token refreshes and other auth events are ignored — the connector
/// refreshes credentials on demand, so an active connection survives them.
class PowerSyncManagerImpl implements PowerSyncManager, Disposable {
  final PowerSyncDatabase _database;
  final PowerSyncBackendConnector _connector;
  final SupabaseWrapper _supabaseWrapper;
  final _logger = AppLogger().tag('PowerSyncManager');

  StreamSubscription<supabase.AuthState>? _authSubscription;

  /// Whether a sync connection is currently established. Guards against
  /// redundant [connect] calls when several auth events arrive in succession.
  bool _connected = false;

  PowerSyncManagerImpl({
    required PowerSyncDatabase database,
    required PowerSyncBackendConnector connector,
    required SupabaseWrapper supabaseWrapper,
  }) : _database = database,
       _connector = connector,
       _supabaseWrapper = supabaseWrapper {
    _initAuthListener();
  }

  @override
  PowerSyncDatabase get database => _database;

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

    // Handle the already-authenticated case: when the session is restored
    // synchronously during bootstrap, the [signedIn] event may have been
    // emitted before this subscription was attached.
    if (_supabaseWrapper.isAuthenticated) {
      unawaited(connect());
    }
  }

  @override
  Future<void> connect() async {
    if (_connected) {
      return;
    }
    _connected = true;
    _logger.info('Starting PowerSync sync connection');
    try {
      await _database.connect(connector: _connector);
    } catch (error, stackTrace) {
      _connected = false;

      _logger.warning('Failed to start PowerSync sync', error, stackTrace);
    }
  }

  @override
  Future<void> disconnectAndClear() async {
    if (!_connected) {
      return;
    }
    _connected = false;
    _logger.info('Disconnecting PowerSync and clearing local synced data');
    try {
      await _database.disconnectAndClear();
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to disconnect and clear PowerSync',
        error,
        stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }
}
