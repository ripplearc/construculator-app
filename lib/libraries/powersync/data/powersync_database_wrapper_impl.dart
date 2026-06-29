// coverage:ignore-file

import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// Default [PowerSyncDatabaseWrapper] that forwards to the opened
/// [PowerSyncDatabase].
///
/// Each row returned by the underlying SDK is a `Row` (a `Map`-backed,
/// unmodifiable view tied to the result set). This implementation copies every
/// row into a plain, mutable `Map<String, dynamic>` so callers above the
/// data-source layer never depend on sqlite types or row lifetimes.
///
/// Marked `coverage:ignore-file` because it only forwards to the native
/// `PowerSyncDatabase`, which cannot be exercised without the platform SQLite
/// extension; behaviour is verified through `FakePowerSyncDatabaseWrapper` in
/// feature tests instead.
class PowerSyncDatabaseWrapperImpl implements PowerSyncDatabaseWrapper {
  final PowerSyncDatabase _database;

  PowerSyncDatabaseWrapperImpl({required PowerSyncDatabase database})
    : _database = database;

  /// Runs [sql] once and returns every matching row as a plain mutable map.
  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final result = await _database.getAll(sql, parameters);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Watches [sql] and re-emits the full result set as plain mutable maps
  /// whenever a table it reads from changes.
  @override
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = kDefaultWatchThrottle,
  }) {
    return _database
        .watch(sql, parameters: parameters, throttle: throttle)
        .map(
          (result) =>
              result.map((row) => Map<String, dynamic>.from(row)).toList(),
        );
  }

  /// Executes a write ([sql]) against the local database.
  @override
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await _database.execute(sql, parameters);
  }

  @override
  Future<T> writeTransaction<T>(Future<T> Function(WriteContext tx) action) {
    return _database.writeTransaction(
      (ctx) => action(_SqliteWriteContextAdapter(ctx)),
    );
  }

  /// Subscribes to the on-demand sync stream [name] and returns a handle that
  /// releases the subscription when unsubscribed.
  @override
  Future<SyncStreamHandle> syncStream(String name) async {
    final subscription = await _database.syncStream(name).subscribe();
    // A per-subscription forwarding adapter has subscription-scoped lifetime
    // and cannot be DI-managed.
    // ignore: no_direct_instantiation, reason: subscription-scoped adapter
    return _PowerSyncStreamHandle(subscription);
  }
}

/// Adapts [SqliteWriteContext] to the project-owned [WriteContext] seam,
/// keeping the sqlite_async type out of the data-source layer.
class _SqliteWriteContextAdapter implements WriteContext {
  final SqliteWriteContext _ctx;

  _SqliteWriteContextAdapter(this._ctx);

  @override
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await _ctx.execute(sql, parameters);
  }
}

/// Forwards [unsubscribe] to the underlying PowerSync [SyncStreamSubscription],
/// keeping that type out of the data-source layer.
class _PowerSyncStreamHandle implements SyncStreamHandle {
  final SyncStreamSubscription _subscription;

  _PowerSyncStreamHandle(this._subscription);

  @override
  void unsubscribe() => _subscription.unsubscribe();
}
