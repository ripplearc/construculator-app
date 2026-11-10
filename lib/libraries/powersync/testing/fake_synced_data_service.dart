// coverage:ignore-file
import 'package:construculator/libraries/powersync/interfaces/synced_data_service.dart';

/// [SyncedDataService] for tests that records its calls and can be made to
/// fail.
class FakeSyncedDataService implements SyncedDataService {
  /// Number of times [deleteSyncedDataAndUnsentEdits] has been called.
  int deleteCallCount = 0;

  /// When true, [deleteSyncedDataAndUnsentEdits] throws.
  bool shouldThrowOnDelete = false;

  @override
  Future<void> deleteSyncedDataAndUnsentEdits() async {
    deleteCallCount++;
    if (shouldThrowOnDelete) throw StateError('delete failed');
  }
}
