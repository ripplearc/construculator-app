// coverage:ignore-file

/// Default throttle for [PowerSyncDatabaseWrapper.watch]: coalesces rapid
/// successive change events into a single emission. Matches PowerSync's own
/// `watch` default; shared by the interface, implementation, and fake so the
/// value lives in one place.
const Duration kDefaultWatchThrottle = Duration(milliseconds: 30);

/// Project-owned write context passed to [PowerSyncDatabaseWrapper.writeTransaction].
///
/// Keeps `sqlite_async`'s `SqliteWriteContext` out of the data-source layer —
/// callers depend only on this narrow interface, not on the underlying SDK type.
abstract class WriteContext {
  /// Executes a write [sql] within the enclosing transaction.
  ///
  /// [parameters] are bound positionally to `?` placeholders in [sql].
  Future<void> execute(String sql, [List<Object?> parameters = const []]);
}

/// Thin, project-owned seam over `PowerSyncDatabase`.
///
/// Features (data sources) depend on this interface rather than on
/// `PowerSyncDatabase` directly, for the same reasons `SupabaseWrapper` sits in
/// front of the Supabase client:
/// - `PowerSyncDatabase` is a heavy native object (SQLite + FFI + isolate);
///   faking it via `implements PowerSyncDatabase` + `noSuchMethod` is fragile.
/// - The surface a feature needs is tiny; the full database API is dozens of
///   methods plus inherited transaction APIs.
/// - Cross-cutting concerns (logging, retry, error normalization) live in one
///   implementation instead of being sprinkled across data sources.
///
/// Rows are returned as plain `List<Map<String, dynamic>>` so that no
/// PowerSync / sqlite types leak above the data-source layer (mirroring
/// `SupabaseWrapper`, which returns the same shape).
///
/// The surface intentionally starts small and grows as features require it.
/// Deliberately omitted for now:
/// - `currentStatus` / `statusStream` — `SyncStatus` has an `@internal`
///   constructor, so it cannot be faked cleanly. Expose a project-owned sync
///   status value object when a sync indicator is actually built.
abstract class PowerSyncDatabaseWrapper {
  /// Runs [sql] once and returns all matching rows.
  ///
  /// [parameters] are bound positionally to `?` placeholders in [sql].
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]);

  /// Watches [sql] and re-emits the full result set whenever any table the
  /// query reads from changes.
  ///
  /// Emits immediately with the current result, then on every relevant local
  /// or synced mutation — making the returned stream the single source of truth
  /// for reactive UI. [parameters] are bound positionally to `?` placeholders.
  /// [throttle] coalesces rapid successive changes into a single emission.
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = kDefaultWatchThrottle,
  });

  /// Executes a write ([sql]) against the local database.
  ///
  /// The change is applied to local SQLite immediately (so any [watch] stream
  /// re-emits at once) and queued for upload by the connector in the
  /// background. [parameters] are bound positionally to `?` placeholders.
  Future<void> execute(String sql, [List<Object?> parameters = const []]);

  /// Runs [action] inside a single write transaction.
  ///
  /// All writes issued through the [WriteContext] passed to [action] are
  /// applied atomically — PowerSync's sync uploader sees them as a single unit,
  /// so the server never observes partial state (e.g., a cost estimate without
  /// its line items). The transaction is committed when [action] completes
  /// normally and rolled back if it throws.
  Future<T> writeTransaction<T>(Future<T> Function(WriteContext tx) action);

  /// Activates the on-demand sync stream named [name] (declared in the backend
  /// sync rules and referenced from `schema.dart`) so its rows begin
  /// downloading into local SQLite.
  ///
  /// On-demand streams only sync while at least one subscription is active, so
  /// callers must release the returned [SyncStreamHandle] (via
  /// [SyncStreamHandle.unsubscribe]) once the stream is no longer needed —
  /// typically when the watching subscription that activated it is cancelled.
  ///
  /// Membership and feature permissions are derived from the JWT server-side;
  /// no parameters are passed from the client. Returning a project-owned
  /// [SyncStreamHandle] (rather than PowerSync's `SyncStreamSubscription`)
  /// keeps PowerSync types out of the data-source layer.
  Future<SyncStreamHandle> syncStream(String name);
}

/// A project-owned handle to an activated on-demand sync stream, returned by
/// [PowerSyncDatabaseWrapper.syncStream].
///
/// Kept as a small, project-owned interface so no PowerSync / sqlite types leak
/// above the data-source layer (mirroring the row-shape rule on the wrapper).
abstract class SyncStreamHandle {
  /// Releases this subscription's interest in the stream.
  ///
  /// Once every subscription for a stream has been released, the stream stops
  /// syncing (after any server-side time-to-live), so cancelling a watch that
  /// activated a stream should call this to avoid syncing data nothing is
  /// watching.
  void unsubscribe();
}
