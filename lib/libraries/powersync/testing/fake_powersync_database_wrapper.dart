import 'dart:async';

import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';

/// A recorded call to [FakePowerSyncDatabaseWrapper.getAll],
/// [FakePowerSyncDatabaseWrapper.watch], or
/// [FakePowerSyncDatabaseWrapper.execute].
typedef RecordedSqlCall = ({String sql, List<Object?> parameters});

/// Behaviour-shaped fake of [PowerSyncDatabaseWrapper] for feature, repository,
/// and data-source tests.
///
/// Unlike [FakePowerSyncDatabase] — which exists only for connector tests, that
/// receive a real `PowerSyncDatabase` from the PowerSync runtime — this fake
/// implements the narrow wrapper seam features actually use. It records calls
/// for assertions, lets tests script [getAll] results and [watch] emissions per
/// SQL string, and can be configured to throw.
class FakePowerSyncDatabaseWrapper implements PowerSyncDatabaseWrapper {
  /// Scripted [getAll] results, keyed by exact SQL string.
  final Map<String, List<Map<String, dynamic>>> _getAllResults = {};

  /// Live [watch] controllers, keyed by exact SQL string.
  final Map<String, StreamController<List<Map<String, dynamic>>>>
  _watchControllers = {};

  /// Latest value emitted (or seeded) per watched SQL string, replayed to new
  /// listeners so subscribing after [emitWatch] still sees the current state —
  /// mirroring how real `watch` emits immediately on listen.
  final Map<String, List<Map<String, dynamic>>> _watchSeed = {};

  /// Every [getAll] call, in order.
  final List<RecordedSqlCall> getAllCalls = [];

  /// Every [watch] call, in order.
  final List<RecordedSqlCall> watchCalls = [];

  /// Every [execute] call, in order.
  final List<RecordedSqlCall> executeCalls = [];

  /// Every [writeTransaction] invocation, in order (call count only — writes
  /// within the transaction appear in [executeCalls] as usual).
  int writeTransactionCallCount = 0;

  /// Every [syncStream] activation, in order (by stream name).
  final List<String> syncStreamCalls = [];

  /// Names of streams whose returned [SyncStreamHandle] has been unsubscribed,
  /// in order — so tests can assert an activated stream is released on cancel.
  final List<String> syncStreamUnsubscribes = [];

  /// When set, every [getAll] call throws this error on every call until
  /// explicitly cleared (`getAllError = null`) or [reset] is called — it does
  /// NOT self-clear after one use.
  Object? getAllError;

  /// When set, every [execute] call throws this error on every call until
  /// explicitly cleared (`executeError = null`) or [reset] is called — it does
  /// NOT self-clear after one use.
  Object? executeError;

  /// When set, every [syncStream] call throws this error until it is cleared
  /// (set back to `null`) or [reset] is called.
  Object? syncStreamError;

  /// Scripts [rows] as the result of [getAll] for [sql].
  void stubGetAll(String sql, List<Map<String, dynamic>> rows) {
    _getAllResults[sql] = rows;
  }

  /// Emits [rows] to listeners of `watch(sql)` and records it as the current
  /// value, so later listeners replay it on subscription.
  void emitWatch(String sql, List<Map<String, dynamic>> rows) {
    _watchSeed[sql] = rows;
    final controller = _watchControllers[sql];
    if (controller != null && !controller.isClosed) {
      controller.add(rows);
    }
  }

  /// Emits [error] to listeners of `watch(sql)`.
  void emitWatchError(String sql, Object error) {
    final controller = _watchControllers[sql];
    if (controller != null && !controller.isClosed) {
      controller.addError(error);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    getAllCalls.add((sql: sql, parameters: parameters));
    final error = getAllError;
    if (error != null) {
      throw error;
    }
    return _getAllResults[sql] ?? const [];
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = kDefaultWatchThrottle,
  }) {
    watchCalls.add((sql: sql, parameters: parameters));
    final controller = _watchControllers.putIfAbsent(
      sql,
      () => StreamController<List<Map<String, dynamic>>>.broadcast(),
    );
    // Replay the latest seeded value on listen, then forward live emissions.
    return Stream.multi((listener) {
      final seed = _watchSeed[sql];
      if (seed != null) {
        listener.add(seed);
      }
      final subscription = controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    executeCalls.add((sql: sql, parameters: parameters));
    final error = executeError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<T> writeTransaction<T>(Future<T> Function(WriteContext tx) action) {
    writeTransactionCallCount++;
    return action(_FakeWriteContext(this));
  }

  @override
  Future<SyncStreamHandle> syncStream(String name) async {
    syncStreamCalls.add(name);
    final error = syncStreamError;
    if (error != null) {
      throw error;
    }
    return _FakeSyncStreamHandle(() => syncStreamUnsubscribes.add(name));
  }

  /// Clears recorded calls, scripted results, errors, and watch seeds, and
  /// closes any open [watch] controllers — returning the fake to its initial
  /// state so it can be reused across tests.
  void reset() {
    _getAllResults.clear();
    _watchSeed.clear();
    getAllCalls.clear();
    watchCalls.clear();
    executeCalls.clear();
    writeTransactionCallCount = 0;
    syncStreamCalls.clear();
    syncStreamUnsubscribes.clear();
    getAllError = null;
    executeError = null;
    syncStreamError = null;
    _closeWatchControllers();
  }

  /// Closes all open [watch] controllers.
  void dispose() {
    _closeWatchControllers();
  }

  void _closeWatchControllers() {
    for (final controller in _watchControllers.values) {
      controller.close();
    }
    _watchControllers.clear();
  }
}

/// Routes writes issued inside [FakePowerSyncDatabaseWrapper.writeTransaction]
/// through the fake's own [execute], so they appear in [executeCalls] and
/// respect [executeError] — no real transaction semantics needed in tests.
class _FakeWriteContext implements WriteContext {
  final FakePowerSyncDatabaseWrapper _fake;

  _FakeWriteContext(this._fake);

  @override
  Future<void> execute(String sql, [List<Object?> parameters = const []]) =>
      _fake.execute(sql, parameters);
}

/// A [SyncStreamHandle] whose [unsubscribe] runs the callback the fake uses to
/// record the release, so tests can assert an activated stream is released.
class _FakeSyncStreamHandle implements SyncStreamHandle {
  final void Function() _onUnsubscribe;

  _FakeSyncStreamHandle(this._onUnsubscribe);

  @override
  void unsubscribe() => _onUnsubscribe();
}
