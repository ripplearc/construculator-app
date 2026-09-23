---
name: code-data-powersync
description: |
  Data layer for PowerSync-synced (offline-first) tables. Write DataSources and
  RepositoryImpls that read through reactive `watch()` streams and write via
  optimistic local `execute()`, behind the `PowerSyncDatabaseWrapper` interface.

  Use this INSTEAD of `code-data` when the feature reads/writes a table that is
  synced via PowerSync (see `lib/libraries/powersync/models/schema.dart`).
  Use plain `code-data` (SupabaseWrapper, request/response) for non-synced tables.

  ⚠️ INVOCATION: Only when the ticket touches a PowerSync-synced table's data layer.

  Trigger: "wire a powersync feature", "add a synced/offline-first data source",
  "watch a synced table", "on-demand sync stream", mentions of watch()/execute()/
  syncStream on a schema table.

disable-model-invocation: false
---

# Code Data (PowerSync) Skill

**Verb:** Write the data layer for an offline-first, PowerSync-synced table.

**Input:** Plan and domain interfaces from `code-domain`: repository interface, entities, failures.

This skill uses the same layering and error boundary as `code-data`. The DataSource
rethrows errors. The RepositoryImpl logs and maps each error once. Two things differ
from `code-data`: reads are reactive `Stream`s, and writes are optimistic local
mutations. If the table is not in `schema.dart`, use `code-data` instead.

## 1. The wrapper interface

Features never touch `PowerSyncDatabase` directly. Depend on
[`PowerSyncDatabaseWrapper`](../../lib/libraries/powersync/interfaces/powersync_database_wrapper.dart)
instead. It returns plain `List<Map<String, dynamic>>` rows. It is already bound in
[`powersync_module.dart`](../../lib/libraries/powersync/powersync_module.dart), so inject
it. Never open the database or touch the connector yourself.

| Method | Use it for |
|--------|-----------|
| `Stream<List<Map>> watch(sql, {parameters, throttle})` | **Default read.** Re-emits on every local *or* synced change. |
| `Future<List<Map>> getAll(sql, [parameters])` | **One-shot only.** A validation lookup, or a read-back after a write. |
| `Future<void> execute(sql, [parameters])` | **Single-row write.** Local SQLite now, queued for upload. |
| `Future<T> writeTransaction<T>((WriteContext tx) → Future<T>)` | **Atomic write.** Use only when 2+ rows must land as a unit. `tx` exposes `execute` only. |
| `Future<SyncStreamHandle> syncStream(name)` | **On-demand sync.** Handle's `unsubscribe()` must be called on cancel. Not idempotent. |

If the wrapper interface is missing something you need, add it in one change: to the
interface, to `PowerSyncDatabaseWrapperImpl`, and to `FakePowerSyncDatabaseWrapper`, with
a test. Never work around the wrapper.

## 2. The two rules

1. **Read reactively.** Anything shown on screen reads through `watch()`. Use `getAll()`
   only when the read is genuinely one-shot.
2. **Treat `watch()` as the only place state comes from, even right after a write.** Never
   re-fetch data or patch UI state by hand. A local write makes every relevant stream
   re-emit on its own.
   *Exception:* if a write's contract must return the mutated entity, read it back with
   `getAll()` (a local read, not a round-trip to the server). Throw if that read-back comes
   back empty.

## 3. Class shapes

| Class | Naming | Returns | Notes |
|-------|--------|---------|-------|
| **DataSource** (interface) | `PowerSync{Noun}DataSource` | `Stream`/`Future` of DTOs | The `PowerSync` prefix goes on the *interface*. The request/response `{Noun}DataSource` can still exist at the same time during a migration. Never return `Either` here. Always rethrow. |
| **DataSource** (impl) | `PowerSync{Noun}DataSourceImpl` | same | Owns on-demand activation (see §5). `_logger.debug()` on success is fine. Never log errors at this layer. |
| **RepositoryImpl** | `{Noun}RepositoryImpl` | `Stream<Either<Failure, T>>` / `Future<Either<Failure, void>>` | **This is the error boundary.** It maps exceptions to `Failure` and logs each one exactly once. |
| **DTO** | `{Noun}Dto` | None | Use `fromRow` for SQLite rows. `fromJson` keeps the Supabase JSON shape (see §7). |

Each of these classes is stateless. When two UIs read the same table, they share one
`addLazySingleton` instance. They differ only by which query they call, for example
`watchRecent(projectId, {limit})` versus `watchAll(projectId)`, never by having separate
instances.

## 4. Writes: optimistic, local-first

- **A successful write means "persisted locally and queued for upload."** It does not mean
  "the server accepted it." The returned `Either` can only ever carry a *local* failure.
- **Server rejection happens later, asynchronously.** If the connector sees a permanent
  RLS denial (`42501`), it completes the transaction anyway so the upload queue isn't
  blocked, and the optimistic row stays in place. Surfacing that rejection to the user goes
  through the conflict channel (`CA-660`), not through this write's return value.
- **Write ids and timestamps explicitly.** Get the id from the injected
  [`UuidGenerator`](../../lib/libraries/uuid/interfaces/uuid_generator.dart) interface, and
  get the time from `Clock`. Never call `Uuid().v4()` inline. Tests need to assert the exact
  insert parameters, and an inline call makes that impossible.
- **Use `writeTransaction` only for an atomic multi-table write.** It commits every row
  together and rolls back all of them if the callback throws. For a single row, use bare
  `execute()`.

> 🛑 **Decision gate.** Sometimes the user experience genuinely needs to know the server
> accepted the write. Locking an estimate is one example, where showing "saved" before the
> server agrees is wrong. When that happens, **stop and ask the user** how to handle
> confirmation and conflicts instead of assuming the optimistic default fits.

## 5. Backend invariants (separate repo)

The rules for what syncs and to whom sit in the backend repo. You cannot read that repo
from here.

> 🛑 **Ask first.** Before writing the data layer, ask the user to paste two things from
> the backend repo: this feature's stream block from `sync-config.yaml` /
> `sync-streams.yaml`, and the table's column list. Do not guess the stream name or which
> columns are selected. A wrong guess fails silently, with no error to warn you. If the
> user can't produce this, tell them the feature is blocked on it, and write only the parts
> of the data layer that don't depend on it.

Once you have that pasted config, check each of these against it:

- [ ] **Every column in `schema.dart` must also be selected by the matching stream in
      `sync-streams.yaml`.** If a column is missing from the stream's `SELECT`, rows lose
      that data silently. No error is raised.
- [ ] **The RLS policy must mirror what the connector does.** It must allow `upsert`,
      `update`, and `delete`, each keyed on `id`.
- [ ] **The table must be in the Postgres publication.** If it isn't, the table never
      syncs down at all.
- [ ] **Permissions must be derived from the JWT on the server side.** The client must
      pass no permission parameters itself.
- [ ] **Register on-demand streams by their sync-stream name, not the table name.** For
      example, the stream for table `cost_estimates` is named `user_cost_estimates`. Using
      the wrong name activates nothing, with no error.

## 6. Wiring an on-demand synced table

An always-on synced table follows the same pattern, just without the activation step.

### 6.1 DataSource owns lazy activation

Activation is tied to the subscription's lifecycle, not to when the object is constructed:
the table only syncs while something is actively watching it. Write this once per data
source, as a private method:
`Stream<T> _watchWithSyncStream<T>({sql, parameters, mapRows, dedupe})`. Each public method
then only needs to supply its own query and how to turn rows into its return type. Build
this with `Stream.multi` so that activation runs separately for each listener.

Hold these five rules when you write it:

- **Set `controller.onCancel` before the first `await`.** Dart will not replay a cancel
  that happens before the callback is assigned. If you set it after an `await`, a cancel
  that races your activation code can leak the sync-stream handle.
- **Release the handle through one helper that nulls the field before calling
  `unsubscribe()`.** Calling `unsubscribe()` twice is a bug, and both `onCancel` and the
  post-await checks below can reach this same code path.
- **After every `await`, re-check `listenerCancelled || !controller.hasListener`.** Do
  this after `syncStream()` returns, and again after the inner subscription is wired up.
  If the listener is gone, release the handle and return immediately.
- **Treat a `syncStream()` throw as terminal.** Catch it, call
  `controller.addError(...)`, then call `controller.close()`. Never leave a stream open
  that can no longer emit anything.
- **On cancel, cancel the inner `watch()` subscription first, then release the sync-stream
  handle, then null both fields.**

**On `dedupe`:** `watch()` re-fires whenever *any* row in the queried table changes, even
one unrelated to what you're watching. That means a single-row watch can rebuild an
identical value just because some other row changed. Pass `true` for shapes that support
value equality, such as a single DTO or a scalar. Leave it off for `List<Dto>`. Dart
compares lists by identity, not by value, so passing `true` there does nothing and can be
mistaken for real protection.

> ⚠️ **An empty stream does not mean "no permission."** If the server denies permission,
> no rows sync down and `watch()` emits `[]`. That looks the same as there simply being no
> rows yet. Check permission upstream of the stream. Never infer it from an empty
> result.

### 6.2 RepositoryImpl: the error boundary

`Either` exists only at this layer, never below it. For reads: map the successful case to
entities inside `Right`. In the error case, log once (via `AppLogger().tag(...)`) and map
to a domain `Failure`. A `watch()` error is recoverable. Map it to `Left` and keep the
stream alive. A `syncStream()` activation failure is not recoverable. The DataSource has
already closed the stream, so that `Left` is the final event, and the UI must offer a way
to re-subscribe.

For writes: use `try`/`catch`. On success, return `Right(null)`, meaning "saved locally
and queued" as described in §4. On a local error, return `Left`.

Reuse `code-data`'s existing exception-to-`Failure` mapping: a timeout or socket error
maps to a warning, a Postgrest error maps to an error, and an unrecognized case becomes
`UnexpectedFailure`. **Always reuse an existing `{Feature}Failure` type. Never invent a
new one inline.**

### 6.3 Presentation & DI

- **Cubit/Bloc:** Subscribe when the Cubit/Bloc is created. Emit a new state for each
  `Either` the stream produces. Cancel the subscription in `close()`. Never patch the list
  by hand after a write. Let the stream do it.
- **DI:** Register with `addLazySingleton`, in the module that owns the feature:
  `{feature}_module.dart`, or `{name}_library_module.dart` when the code is shared across
  features. Cost estimation, for example, sits in `lib/libraries/estimation/`.
- **Migrating an existing Supabase feature:** Register the new PowerSync DataSource
  alongside the existing request/response one. Keep the repository bound to the old
  implementation until the actual cutover PR.

## 7. SQLite encodings

These encoding rules come from [`schema.dart`](../../lib/libraries/powersync/models/schema.dart):

- **Booleans are stored as integers.** Convert in two separate places. On read, convert in
  `Dto.fromRow` (`(row['is_locked'] as int? ?? 0) != 0`). On write, convert at the insert
  (`e.isLocked ? 1 : 0`). This is because `toJson`/`fromJson` keep using the Supabase
  boolean shape, not the SQLite integer shape.
- **Timestamps are stored as `text`.** Parse and format ISO strings yourself.
- **Numeric columns:** a `Column.real` maps to `double`, and a `Column.integer` maps to
  `int`.
- **`id` is added by PowerSync automatically.** Don't redeclare it in your schema, but do
  set its value yourself on insert.

## 8. Testing (see `write-tests`, `write-tests-mutation`)

Test against
[`FakePowerSyncDatabaseWrapper`](../../lib/libraries/powersync/testing/fake_powersync_database_wrapper.dart).
Never test against the real database.

- **Reads:** Use `fake.stubGetAll(sql, rows)` for one-shot reads. Use
  `fake.emitWatch(sql, rows)` for streamed reads. A seeded value replays to a subscriber
  that joins later.
- **Errors:** Use `fake.emitWatchError(sql, err)`, `getAllError`, `executeError`, or
  `syncStreamError` to simulate each kind of failure.
- **Writes:** Assert that `fake.executeCalls` contains the expected `(sql, parameters)`
  pair. Check the actual bound parameters, not just that the call happened.
- **Transactions:** Check `fake.writeTransactionCallCount`. Inner `tx.execute()` calls
  still show up in `executeCalls`, in order. `writeTransactionError` makes the transaction
  fail before the callback runs at all.
- **Activation:** After the first subscription, `fake.syncStreamCalls` contains the stream
  name.
- **Release:** After cancel, `fake.syncStreamUnsubscribes` contains the stream name exactly
  once.
- **Cancel during activation:** Call `listen()`, then `cancel()` synchronously, then
  `await pumpEventQueue()`. This asserts that a handle acquired after the subscriber left
  is still released.
- Call `fake.reset()` between tests, and `fake.dispose()` in teardown.

## Checklist

- [ ] Reads go through `watch()`. Any `getAll()` one-shot is justified.
- [ ] DataSource returns DTOs and rethrows. No `Either` appears below the repository.
- [ ] RepositoryImpl maps to a reused `Failure` and logs each error once.
- [ ] Writes are optimistic. Any write where server acceptance matters was confirmed with
      the user (the §4 gate).
- [ ] `syncStream` activates on the first watch, releases exactly once on cancel, and
      survives a cancel that races activation.
- [ ] No permission is inferred from an empty stream.
- [ ] The backend sync config was asked for and reconciled (§5). Stream name and selected
      columns were confirmed, not guessed.
- [ ] The DTO handles bool-as-int and text timestamps.
- [ ] Tests cover the reactive, error, activation, and release paths.
