// coverage:ignore-file
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:construculator/libraries/network_status/interfaces/connectivity_sdk.dart';

/// [ConnectivitySdk] backed by the `connectivity_plus` plugin.
class ConnectivitySdkImpl implements ConnectivitySdk {
  final Connectivity _connectivity;

  /// Creates the boundary over [connectivity].
  ConnectivitySdkImpl({required this._connectivity});

  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
