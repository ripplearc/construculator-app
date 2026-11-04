import 'package:construculator/libraries/network_status/interfaces/internet_reachability_sdk.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// [InternetReachabilitySdk] backed by the `internet_connection_checker_plus`
/// package.
class InternetReachabilitySdkImpl implements InternetReachabilitySdk {
  final InternetConnection _connection;
  final Duration _checkInterval;

  /// Creates the boundary over [connection], ticking every [checkInterval].
  InternetReachabilitySdkImpl({
    required this._connection,
    required this._checkInterval,
  });

  @override
  Future<bool> checkReachable() => _connection.hasInternetAccess;

  @override
  Stream<void> get checkTicks => Stream<void>.periodic(_checkInterval);

  /// Releases the connection.
  Future<void> dispose() => _connection.dispose();
}
