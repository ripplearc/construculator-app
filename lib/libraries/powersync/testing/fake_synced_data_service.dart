// coverage:ignore-file
import 'package:construculator/libraries/powersync/interfaces/synced_data_service.dart';

/// [SyncedDataService] for tests that records its calls and can be made to
/// fail.
class FakeSyncedDataService implements SyncedDataService {
  /// Number of times [deleteSyncedDataAndUnsentEdits] has been called.
  int deleteCallCount = 0;

  /// When true, [deleteSyncedDataAndUnsentEdits] throws.
  bool shouldThrowOnDelete = false;

  /// Called at the end of every successful delete, so a test can change the
  /// world between two steps of the code under test.
  void Function()? afterDelete;

  @override
  Future<void> deleteSyncedDataAndUnsentEdits() async {
    deleteCallCount++;
    if (shouldThrowOnDelete) throw Exception('delete failed');
    afterDelete?.call();
  }
}
