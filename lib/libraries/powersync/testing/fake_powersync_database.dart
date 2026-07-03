// coverage:ignore-file

import 'package:powersync/powersync.dart';

/// Fake [PowerSyncDatabase] for tests of [PowerSyncBackendConnector]
/// implementations, which receive a real `PowerSyncDatabase` from the PowerSync
/// runtime (e.g. `connector.uploadData(database)`).
///
/// Feature, repository, and data-source tests should use
/// `FakePowerSyncDatabaseWrapper` instead — it fakes the narrow
/// `PowerSyncDatabaseWrapper` seam rather than this full native API.
///
/// Call [setNextTransaction] to control what [getNextCrudTransaction] returns.
/// Each call to [getNextCrudTransaction] consumes and clears the queued
/// transaction, matching real PowerSync behaviour.
class FakePowerSyncDatabase implements PowerSyncDatabase {
  CrudTransaction? _nextTransaction;

  /// Number of times [connect] has been called.
  int connectCallCount = 0;

  /// The connector passed to the most recent [connect] call, or null if
  /// [connect] has not been called.
  PowerSyncBackendConnector? lastConnector;

  /// Number of times [disconnect] has been called.
  int disconnectCallCount = 0;

  /// Number of times [disconnectAndClear] has been called.
  int disconnectAndClearCallCount = 0;

  /// When set, the next [connect] call throws this error, allowing tests to
  /// exercise connection-failure handling.
  Object? connectError;

  /// Queues [transaction] to be returned by the next [getNextCrudTransaction] call.
  void setNextTransaction(CrudTransaction? transaction) {
    _nextTransaction = transaction;
  }

  /// Clears all recorded call counts, the captured connector, the configured
  /// [connectError], and any queued transaction, returning the fake to its
  /// initial state so it can be reused across tests.
  void reset() {
    connectCallCount = 0;
    lastConnector = null;
    disconnectCallCount = 0;
    disconnectAndClearCallCount = 0;
    connectError = null;
    _nextTransaction = null;
  }

  @override
  Future<void> connect({
    required PowerSyncBackendConnector connector,
    SyncOptions? options,
    Duration? crudThrottleTime,
    Map<String, dynamic>? params,
  }) async {
    connectCallCount++;
    lastConnector = connector;
    final error = connectError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  @override
  Future<void> disconnectAndClear({bool clearLocal = true}) async {
    disconnectAndClearCallCount++;
  }

  /// Returns the queued transaction (set via [setNextTransaction]) and clears
  /// it so the following call returns null. One transaction is consumed per
  /// call, mirroring how PowerSync drains the upload queue one item at a time.
  @override
  Future<CrudTransaction?> getNextCrudTransaction() async {
    final transaction = _nextTransaction;
    _nextTransaction = null;
    return transaction;
  }

  /// Falls back to [Object.noSuchMethod] for every other [PowerSyncDatabase]
  /// member. Tests that exercise more of the database API should extend this
  /// class and override the specific methods they need.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake [CrudTransaction] for testing.
///
/// Pass [operations] to control [crud]. Inspect [isCompleted] after
/// calling [complete] to assert the transaction was committed.
class FakeCrudTransaction implements CrudTransaction {
  final List<CrudEntry> _operations;
  bool _isCompleted = false;

  /// Creates a fake transaction backed by [operations], which are exposed
  /// verbatim via [crud].
  FakeCrudTransaction(this._operations);

  /// Whether [complete] has been invoked. Test-only — the real
  /// [CrudTransaction] does not expose completion state.
  bool get isCompleted => _isCompleted;

  /// The operations passed to the constructor. Returned by reference, so
  /// callers should treat the list as read-only.
  @override
  List<CrudEntry> get crud => _operations;

  /// Always null. Real PowerSync assigns transaction IDs internally; tests
  /// have no need to assert on them.
  @override
  int? get transactionId => null;

  /// Returns a closure that marks the transaction as completed when awaited.
  /// The [writeCheckpoint] argument is accepted to match the real signature
  /// but is ignored.
  @override
  Future<void> Function({String? writeCheckpoint}) get complete =>
      ({String? writeCheckpoint}) async {
        _isCompleted = true;
      };

  /// Falls back to [Object.noSuchMethod] for every other [CrudTransaction]
  /// member. Tests that need other members should extend this class.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
