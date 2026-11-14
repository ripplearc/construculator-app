import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/powersync/interfaces/synced_data_service.dart';

/// [SyncedDataService] that asks the [PowerSyncManager] to disconnect and
/// clear, so the manager's connection state stays correct and a later connect
/// works.
class PowerSyncSyncedDataService implements SyncedDataService {
  final PowerSyncManager _manager;

  /// Deletes through the manager that owns the connection.
  PowerSyncSyncedDataService({required this._manager});

  @override
  Future<void> deleteSyncedDataAndUnsentEdits() =>
      _manager.disconnectAndClearOrThrow();
}
