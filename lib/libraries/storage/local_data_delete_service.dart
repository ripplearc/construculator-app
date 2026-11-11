import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/interfaces/synced_data_service.dart';
import 'package:construculator/libraries/powersync/models/local_only_table_registry.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';

/// Thrown when the owner record cannot be read, so nothing is deleted.
class OwnerRecordUnreadableException implements Exception {
  /// An error for a read that returned [OwnerRecordUnknown].
  const OwnerRecordUnreadableException();

  @override
  String toString() =>
      'OwnerRecordUnreadableException: the owner record could not be read';
}

/// The one routine every delete of local-only data uses.
///
/// It sets the pending-delete flag, runs the clear step of every registered
/// local-only table (a device setting is kept) and the clear step of the whole
/// user space of the storage library, deletes the synced data and the unsent
/// edits, then removes the owner record (or replaces it with the
/// arriving user) in one write. A failure after the flag is written leaves the
/// flag set, so the next run finishes the delete.
///
/// It does not guard against overlapping calls: the caller runs one delete at a
/// time and makes sure PowerSync is not connected as another user while it
/// runs. The delete leaves PowerSync disconnected, so the caller connects it
/// again after a successful delete.
class LocalDataDeleteService {
  final OwnerRecordStorageService _ownerRecords;
  final PowerSyncDatabaseWrapper _database;
  final SyncedDataService _syncedData;
  final StorageService _userSpace;
  final Iterable<LocalOnlyTableRegistration> _registrations;

  /// [registrations] are the tables whose clear step runs; production uses
  /// [LocalOnlyTableRegistry.registrations].
  LocalDataDeleteService({
    required this._ownerRecords,
    required this._database,
    required this._syncedData,
    required this._userSpace,
    this._registrations = LocalOnlyTableRegistry.registrations,
  });

  /// Deletes the local-only data on the phone.
  ///
  /// Pass [arrivingUserId] when a different user is signing in: the flag then
  /// names that user and the finished record holds their id. Without it the
  /// flag names nobody and the finished record is removed. A flag that already
  /// names an arriving user keeps naming them while the delete runs, even
  /// without [arrivingUserId], but the finished record is still removed.
  ///
  /// Throws an [OwnerRecordUnreadableException] without deleting anything when
  /// the owner record cannot be read, and an [ArgumentError] when
  /// [arrivingUserId] is empty. Throws the exception of the first step that
  /// fails, with the flag still set.
  Future<void> deleteLocalData({String? arrivingUserId}) async {
    await _setPendingDeleteFlag(arrivingUserId);
    for (final registration in _registrations) {
      await registration.clearForUserChange(_database);
    }
    await _userSpace.clearAll();
    await _syncedData.deleteSyncedDataAndUnsentEdits();
    await _finishRecord(arrivingUserId);
  }

  Future<void> _setPendingDeleteFlag(String? arrivingUserId) async {
    final read = await _ownerRecords.read();
    final current = switch (read) {
      OwnerRecordFound(:final record) => record,
      OwnerRecordAbsent() => null,
      OwnerRecordUnknown() => throw const OwnerRecordUnreadableException(),
    };
    await _ownerRecords.write(
      OwnerRecord(
        userId: current?.userId,
        pendingDelete: _flagFor(arrivingUserId, current?.pendingDelete),
        signOutDate: current?.signOutDate,
      ),
    );
  }

  PendingDelete _flagFor(String? arrivingUserId, PendingDelete? earlierFlag) {
    if (arrivingUserId != null) return PendingDelete.arrivalOf(arrivingUserId);
    if (earlierFlag != null &&
        earlierFlag.kind == PendingDeleteKind.arrivalOfNewUser) {
      return earlierFlag;
    }
    return const PendingDelete.logoutOrNoOwnerRecord();
  }

  Future<void> _finishRecord(String? arrivingUserId) => arrivingUserId == null
      ? _ownerRecords.remove()
      : _ownerRecords.write(OwnerRecord(userId: arrivingUserId));
}
