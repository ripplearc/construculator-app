import 'package:construculator/libraries/network_status/interfaces/network_status.dart';

/// Tells the app whether the phone is online, and when that changes.
///
/// Works before login, because it does not depend on the sync service. Tests
/// drive it by hand with `FakeNetworkStatusService`.
abstract class NetworkStatusService {
  /// The status now. Online until the first reading says otherwise.
  NetworkStatus get current;

  /// Emits the new value of [current] each time it changes, and only then.
  Stream<NetworkStatus> get changes;
}
