import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:construculator/libraries/app_lifecycle/interfaces/app_lifecycle_wrapper.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/network_status/interfaces/connectivity_sdk.dart';
import 'package:construculator/libraries/network_status/interfaces/internet_reachability_sdk.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status_service.dart';

/// [NetworkStatusService] that reports online only when the internet works.
///
/// The operating system says when a network appears or disappears. No network
/// reads as offline at once. A network that appears is checked right away, and
/// the phone reads as online only if the check passes, so a Wi-Fi link with a
/// dead connection stays offline. While the app is on screen and a network is
/// attached, the check repeats on a timer to catch a connection that dies or
/// returns without the system noticing. In the background the timer stops, and
/// it starts again with a check when the app comes back.
///
/// While the app is in the background nothing is checked. Losing the network
/// still reads as offline at once, but a network that appears is left unchecked
/// until the app comes back, so the status keeps its last value until then.
/// Until the app has first been on screen with a network attached, [current] is
/// the starting value, online, and has not been checked.
///
/// Every check starts here, and only the newest one counts: a check that
/// finishes after a newer one started, or after the network was lost, is
/// ignored.
///
/// Starts listening on creation and keeps its subscriptions for the app's whole
/// run. [dispose] releases them.
class NetworkStatusServiceImpl implements NetworkStatusService {
  final _logger = AppLogger().tag('NetworkStatusServiceImpl');
  final ConnectivitySdk _connectivitySdk;
  final InternetReachabilitySdk _reachabilitySdk;
  final AppLifecycleWrapper _appLifecycle;
  final _changes = StreamController<NetworkStatus>.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  late final StreamSubscription<bool> _lifecycleSub;
  StreamSubscription<void>? _ticksSub;
  NetworkStatus _current = NetworkStatus.online;
  bool _hasNetwork = true;
  bool _hasHeardFromSystem = false;
  bool _isDisposed = false;
  int _checkGeneration = 0;

  /// Completes once the first read of the network has finished, whether it was
  /// applied, skipped or failed.
  ///
  /// Does not wait for the internet check, so [current] can still be its
  /// starting value. Meant for tests.
  late final Future<void> ready;

  /// Creates the service and starts listening to [connectivitySdk] and
  /// [appLifecycle]. Internet checks go through [reachabilitySdk].
  NetworkStatusServiceImpl({
    required this._connectivitySdk,
    required this._reachabilitySdk,
    required this._appLifecycle,
  }) {
    _connectivitySub = _connectivitySdk.onConnectivityChanged.listen(
      _onSystemChange,
    );
    _lifecycleSub = _appLifecycle.foregroundChanges.listen(
      (_) => _onForegroundChange(),
    );
    ready = _readInitialStatus();
  }

  @override
  NetworkStatus get current => _current;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  /// Stops listening and checking, and closes [changes].
  Future<void> dispose() async {
    _isDisposed = true;
    await _connectivitySub.cancel();
    await _lifecycleSub.cancel();
    await _stopPolling();
    await _changes.close();
  }

  Future<void> _readInitialStatus() async {
    try {
      final results = await _connectivitySdk.checkConnectivity();
      if (_isDisposed || _hasHeardFromSystem) return;
      _onNetworkChange(results);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to read the initial network status',
        error,
        stackTrace,
      );
      if (!_hasHeardFromSystem) _startChecking();
    }
  }

  void _onSystemChange(List<ConnectivityResult> results) {
    _hasHeardFromSystem = true;
    _onNetworkChange(results);
  }

  void _onNetworkChange(List<ConnectivityResult> results) {
    _hasNetwork = results.any((result) => result != ConnectivityResult.none);
    if (!_hasNetwork) {
      _checkGeneration++;
      unawaited(_stopPolling());
      _apply(NetworkStatus.offline);
      return;
    }
    _startChecking();
  }

  void _onForegroundChange() {
    if (!_hasNetwork) return;
    if (_appLifecycle.isInForeground) {
      _startChecking();
    } else {
      _checkGeneration++;
      unawaited(_stopPolling());
    }
  }

  void _startChecking() {
    if (!_appLifecycle.isInForeground) return;
    _ticksSub ??= _reachabilitySdk.checkTicks.listen(
      (_) => unawaited(_checkNow()),
    );
    unawaited(_checkNow());
  }

  Future<void> _stopPolling() async {
    final subscription = _ticksSub;
    _ticksSub = null;
    await subscription?.cancel();
  }

  Future<void> _checkNow() async {
    final generation = ++_checkGeneration;
    try {
      final isReachable = await _reachabilitySdk.checkReachable();
      if (generation != _checkGeneration) return;
      _apply(isReachable ? NetworkStatus.online : NetworkStatus.offline);
    } catch (error, stackTrace) {
      _logger.error('Failed to check internet access', error, stackTrace);
    }
  }

  void _apply(NetworkStatus status) {
    if (_isDisposed || status == _current) return;
    _current = status;
    _changes.add(status);
  }
}
