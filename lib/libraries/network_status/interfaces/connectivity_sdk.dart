import 'package:connectivity_plus/connectivity_plus.dart';

/// Boundary over the `connectivity_plus` plugin.
///
/// `NetworkStatusServiceImpl` talks to this interface instead of the plugin so
/// its mapping and change detection can be tested against a fake boundary.
abstract class ConnectivitySdk {
  /// Reads the networks the phone is attached to now.
  Future<List<ConnectivityResult>> checkConnectivity();

  /// Emits the attached networks each time the operating system reports a
  /// change.
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}
