import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/network_status/interfaces/connectivity_sdk.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status_service.dart';
import 'package:flutter/foundation.dart';

/// [NetworkStatusService] that follows the operating system's network changes.
///
/// The phone counts as offline only when the system reports no network at all.
/// A network that is attached but cannot reach the internet still reads as
/// online here.
///
/// Starts listening on creation and keeps one subscription for the app's whole
/// run. [dispose] releases it.
class NetworkStatusServiceImpl implements NetworkStatusService {
  final _logger = AppLogger().tag('NetworkStatusServiceImpl');
  final ConnectivitySdk _connectivitySdk;
  final _changes = StreamController<NetworkStatus>.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  NetworkStatus _current = NetworkStatus.online;
  bool _hasHeardFromSystem = false;
  bool _isDisposed = false;

  /// Completes once the first read of the network has finished, whether it was
  /// applied, skipped or failed.
  ///
  /// Meant for tests.
  @visibleForTesting
  late final Future<void> ready;

  /// Creates the service and starts listening to [connectivitySdk].
  NetworkStatusServiceImpl({required this._connectivitySdk}) {
    _subscription = _connectivitySdk.onConnectivityChanged.listen(
      _onSystemChange,
    );
    ready = _readInitialStatus();
  }

  @override
  NetworkStatus get current => _current;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  /// Stops listening to the operating system and closes [changes].
  Future<void> dispose() async {
    _isDisposed = true;
    await _subscription.cancel();
    await _changes.close();
  }

  Future<void> _readInitialStatus() async {
    try {
      final results = await _connectivitySdk.checkConnectivity();
      if (_isDisposed || _hasHeardFromSystem) return;
      _apply(results);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to read the initial network status',
        error,
        stackTrace,
      );
    }
  }

  void _onSystemChange(List<ConnectivityResult> results) {
    _hasHeardFromSystem = true;
    _apply(results);
  }

  void _apply(List<ConnectivityResult> results) {
    final status = _toStatus(results);
    if (status == _current) return;
    _current = status;
    _changes.add(status);
  }

  static NetworkStatus _toStatus(List<ConnectivityResult> results) =>
      results.every((result) => result == ConnectivityResult.none)
      ? NetworkStatus.offline
      : NetworkStatus.online;
}
