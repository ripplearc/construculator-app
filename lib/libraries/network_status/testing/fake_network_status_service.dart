import 'dart:async';

import 'package:construculator/libraries/network_status/interfaces/network_status.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status_service.dart';

/// [NetworkStatusService] that a test moves between online and offline.
///
/// Starts online. Changes are delivered synchronously, so a test sees their
/// effect without pumping.
class FakeNetworkStatusService implements NetworkStatusService {
  final _changes = StreamController<NetworkStatus>.broadcast(sync: true);
  NetworkStatus _current = NetworkStatus.online;

  @override
  NetworkStatus get current => _current;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  /// Sets the status, and tells listeners if it differs from [current].
  void setStatus(NetworkStatus status) {
    if (status == _current) return;
    _current = status;
    _changes.add(status);
  }

  /// Returns to online, for use between tests.
  void reset() => setStatus(NetworkStatus.online);

  /// Closes [changes].
  void dispose() => unawaited(_changes.close());
}
