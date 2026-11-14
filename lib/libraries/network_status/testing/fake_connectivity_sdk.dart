import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:construculator/libraries/network_status/interfaces/connectivity_sdk.dart';

/// [ConnectivitySdk] that a test drives by hand.
///
/// Starts attached to Wi-Fi. Changes are delivered synchronously.
class FakeConnectivitySdk implements ConnectivitySdk {
  final _changes = StreamController<List<ConnectivityResult>>.broadcast(
    sync: true,
  );
  List<ConnectivityResult> _results = [ConnectivityResult.wifi];
  Completer<List<ConnectivityResult>>? _heldCheck;

  /// When true, [checkConnectivity] throws.
  bool shouldThrowOnCheck = false;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() {
    if (shouldThrowOnCheck) {
      return Future.error(StateError('connectivity check failed'));
    }
    return _heldCheck?.future ?? Future.value(_results);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _changes.stream;

  /// Whether anything is listening to [onConnectivityChanged].
  bool get hasListener => _changes.hasListener;

  /// Changes the attached networks, and tells listeners.
  void emit(List<ConnectivityResult> results) {
    _results = results;
    _changes.add(results);
  }

  /// Makes [checkConnectivity] wait until [releaseCheck] is called.
  void holdCheck() => _heldCheck = Completer();

  /// Lets a held [checkConnectivity] finish with [results].
  ///
  /// Returns once whoever was waiting on that check has handled the answer.
  Future<void> releaseCheck(List<ConnectivityResult> results) async {
    final check = _heldCheck;
    _heldCheck = null;
    check?.complete(results);
    await check?.future;
  }

  /// Makes a held [checkConnectivity] fail.
  ///
  /// Returns once whoever was waiting on that check has handled the error.
  Future<void> failHeldCheck() async {
    final check = _heldCheck;
    _heldCheck = null;
    check?.completeError(StateError('connectivity check failed'));
    await check?.future.then((_) {}, onError: (Object _) {});
  }

  /// Closes [onConnectivityChanged].
  void dispose() => unawaited(_changes.close());
}
