import 'package:powersync/powersync.dart';

/// Owns the PowerSync sync lifecycle and ties it to authentication.
///
/// The local database is opened during app bootstrap and is usable offline at
/// all times. Syncing with the backend, however, requires an authenticated
/// session, so the manager [connect]s once the user signs in and
/// [disconnectAndClear]s when they sign out.
///
/// Implementations subscribe to authentication changes themselves, so callers
/// generally do not need to invoke [connect] / [disconnectAndClear] manually —
/// they are exposed for explicit control and testing.
abstract class PowerSyncManager {
  /// The opened local PowerSync database.
  ///
  /// Use this to read and write data; PowerSync records local mutations whether
  /// or not a sync connection is currently active.
  PowerSyncDatabase get database;

  /// Starts syncing with the backend using the configured connector.
  ///
  /// Safe to call when already connected — implementations guard against
  /// establishing duplicate connections.
  Future<void> connect();

  /// Stops syncing and clears all synced data from the local database.
  ///
  /// Call this on sign-out so the next user does not inherit the previous
  /// user's synced rows.
  Future<void> disconnectAndClear();
}
