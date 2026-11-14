// coverage:ignore-file

/// Deletes what PowerSync keeps for the signed-in user.
abstract class SyncedDataService {
  /// Stops syncing and deletes the synced data and the edits that were not yet
  /// sent. It leaves the local-only tables alone, because their registrations
  /// clear them.
  ///
  /// Throws an exception if the delete fails.
  Future<void> deleteSyncedDataAndUnsentEdits();
}
