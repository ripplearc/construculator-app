// coverage:ignore-file
/// Boundary over the `internet_connection_checker_plus` package.
///
/// `NetworkStatusServiceImpl` talks to this interface instead of the package
/// so its checks can be tested against a fake boundary. The service decides
/// when to check, so the package's own change stream is not used.
abstract class InternetReachabilitySdk {
  /// Asks now whether the internet can be reached.
  Future<bool> checkReachable();

  /// Emits once each time the check interval passes, for as long as it is
  /// listened to. Cancelling the subscription stops the timer.
  Stream<void> get checkTicks;
}
