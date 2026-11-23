// coverage:ignore-file

import 'package:powersync/powersync.dart';

/// Owns the PowerSync sync lifecycle and ties it to authentication.
///
/// The local database is opened during app bootstrap and is usable offline at
/// all times. Syncing with the backend, however, requires an authenticated
/// session, so the sign-in check [connect]s it once the user's data is known
/// to belong to them, and [disconnectAndClear]s it after a sign-out until the
/// sign-out handler (CA-1462) exists.
///
/// Implementations do not listen to authentication changes: the caller decides
/// when to connect and disconnect.
abstract class PowerSyncManager {
  /// The opened local PowerSync database.
  ///
  /// Use this to read and write data; PowerSync records local mutations whether
  /// or not a sync connection is currently active.
  PowerSyncDatabase get database;

  /// Starts syncing with the backend using the configured connector.
  ///
  /// Safe to call when already connected — implementations guard against
  /// establishing duplicate connections. Throws when it did not connect.
  Future<void> connect();

  /// Stops syncing and keeps the synced rows. Does nothing when not connected.
  /// The next [connect] clears the kept rows first.
  Future<void> disconnectKeepingData();

  /// Stops syncing and clears all synced data from the local database.
  ///
  /// Call this on sign-out so the next user does not inherit the previous
  /// user's synced rows.
  Future<void> disconnectAndClear();

  /// Stops syncing and deletes the synced data and the unsent edits, whatever
  /// the connection state is, and leaves the local-only tables alone.
  ///
  /// Unlike [disconnectAndClear], it does not skip the delete when the manager
  /// is not connected, and it throws when the delete fails. A later [connect]
  /// retries a failed delete first.
  Future<void> disconnectAndClearOrThrow();
}
