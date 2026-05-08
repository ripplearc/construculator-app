import 'package:powersync/powersync.dart';

/// Fake PowerSync backend connector for testing.
///
/// Allows tests to control authentication state, upload behavior,
/// and simulate various error conditions without requiring a real
/// PowerSync service or Supabase backend.
class FakePowerSyncConnector extends PowerSyncBackendConnector {
  PowerSyncCredentials? _credentials;
  Exception? _uploadError;
  bool _completeTransactionOnError = false;
  final List<CrudTransaction> uploadedTransactions = [];
  final List<CrudEntry> uploadedOperations = [];

  /// Sets the credentials to return from [fetchCredentials].
  void setCredentials(PowerSyncCredentials? credentials) {
    _credentials = credentials;
  }

  /// Sets an error to throw during [uploadData].
  ///
  /// If [completeTransactionOnError] is true, the transaction will be
  /// completed before throwing the error (simulating RLS denial handling
  /// where the transaction is marked complete to unblock the upload queue).
  void setUploadError(
    Exception error, {
    bool completeTransactionOnError = false,
  }) {
    _uploadError = error;
    _completeTransactionOnError = completeTransactionOnError;
  }

  /// Clears any configured upload error.
  void clearUploadError() {
    _uploadError = null;
    _completeTransactionOnError = false;
  }

  /// Clears all recorded upload history.
  void clearUploadHistory() {
    uploadedTransactions.clear();
    uploadedOperations.clear();
  }

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    return _credentials;
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    uploadedTransactions.add(transaction);
    uploadedOperations.addAll(transaction.crud);

    final error = _uploadError;
    if (error != null) {
      if (_completeTransactionOnError) {
        await transaction.complete();
      }
      throw error;
    }

    await transaction.complete();
  }
}
