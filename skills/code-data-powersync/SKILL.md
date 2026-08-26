---
name: code-data-powersync
description: |
  Data layer for PowerSync-synced (offline-first) tables. Write DataSources and
  RepositoryImpls that read through reactive `watch()` streams and write via
  optimistic local `execute()`, behind the `PowerSyncDatabaseWrapper` seam.

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

**Input:** Plan + domain interfaces (`code-domain`) — repository interface, entities, failures.

Same layering and error boundary as `code-data` (DataSource rethrows; RepositoryImpl
logs+maps once). What changes: reads are reactive `Stream`s, writes are optimistic local
mutations. Table not in `schema.dart` → use `code-data` instead.

## 1. The seam

Features never touch `PowerSyncDatabase`. Depend on
[`PowerSyncDatabaseWrapper`](../../lib/libraries/powersync/interfaces/powersync_database_wrapper.dart),
which returns plain `List<Map<String, dynamic>>` rows. Already bound in
[`powersync_module.dart`](../../lib/libraries/powersync/powersync_module.dart) — inject it;
never open the DB or touch the connector.

| Method | Use it for |
|--------|-----------|
| `Stream<List<Map>> watch(sql, {parameters, throttle})` | **Default read.** Re-emits on every local *or* synced change. |
| `Future<List<Map>> getAll(sql, [parameters])` | **One-shot only** — validation lookups, read-back after a write. |
| `Future<void> execute(sql, [parameters])` | **Single-row write.** Local SQLite now, queued for upload. |
| `Future<T> writeTransaction<T>((WriteContext tx) → Future<T>)` | **Atomic write.** Use only when 2+ rows must land as a unit. `tx` exposes `execute` only. |
| `Future<SyncStreamHandle> syncStream(name)` | **On-demand sync.** Handle's `unsubscribe()` must be called on cancel. Not idempotent. |

Seam lacks what you need? Add it to the interface, `PowerSyncDatabaseWrapperImpl`, and
`FakePowerSyncDatabaseWrapper` in one change with a test. Never reach around it.

## 2. The two rules

1. **Read reactively.** Anything on screen reads through `watch()`. `getAll()` only when
   genuinely one-shot.
2. **`watch()` is the source of truth, including after a write.** Never re-fetch or patch
   UI state by hand — the local write makes every relevant stream re-emit.
   *Exception:* a write whose contract returns the mutated entity needs a `getAll()`
   read-back (local read, not a round-trip). Throw if it comes up empty.

## 3. Class shapes

| Class | Naming | Returns | Notes |
|-------|--------|---------|-------|
| **DataSource** (interface) | `PowerSync{Noun}DataSource` | `Stream`/`Future` of DTOs | Prefix is on the *interface* — the request/response `{Noun}DataSource` may coexist during migration. **No `Either`.** Always rethrows. |
| **DataSource** (impl) | `PowerSync{Noun}DataSourceImpl` | same | Owns on-demand activation (§5). `_logger.debug()` on success is fine; never log errors here. |
| **RepositoryImpl** | `{Noun}RepositoryImpl` | `Stream<Either<Failure, T>>` / `Future<Either<Failure, void>>` | **Error boundary.** Maps to `Failure`, logs once. |
| **DTO** | `{Noun}Dto` | — | `fromRow` for SQLite; `fromJson` stays Supabase-shaped (§6). |

Stateless — two UIs over one table share the `addLazySingleton` instance and differ only
by query (`watchRecent(projectId, {limit})` vs `watchAll(projectId)`), not by instance.

## 4. Writes — optimistic, local-first

- **Success means "persisted locally + queued" — NOT "server accepted."** The returned
  `Either` can only carry a *local* failure.
- **Server rejection is asynchronous.** The connector treats an RLS denial (`42501`) as
  permanent and completes the transaction to unblock the queue; the optimistic row stays.
  User-facing surfacing is the conflict channel (`CA-660`), not this return value.
- **Write ids/timestamps explicitly.** Id from the injected
  [`UuidGenerator`](../../lib/libraries/uuid/interfaces/uuid_generator.dart) seam, times
  from `Clock` — never `Uuid().v4()` inline, or the insert's params can't be asserted.
- **`writeTransaction` for atomic multi-table writes** — commits together, rolls back on
  throw. Bare `execute()` for single rows.

> 🛑 **Decision gate.** When *server acceptance* matters to the UX (locking an estimate,
> anything where showing "saved" before the server agrees is wrong), **stop and ask the
> user** how confirmation/conflict should work. The optimistic default is not universal.

## 5. Backend invariants (separate repo)

Sync rules live in the backend repo — **you cannot read it from here.**

> 🛑 **Ask first.** Before writing the data layer, ask the user to paste this feature's
> stream block (and the table's column list) from the backend repo's `sync-config.yaml` /
> `sync-streams.yaml`. Do not guess the stream name or the SELECTed columns — a wrong guess
> fails silently, not loudly. If the user can't produce it, say the feature is blocked on it
> and write only what doesn't depend on it.

Reconcile against that pasted config:

- [ ] **Schema ↔ stream-SELECT parity.** Every `schema.dart` column must be SELECTed by the
      matching `sync-streams.yaml` stream. **Mismatch = silent data loss**, no error.
- [ ] **RLS mirrors the connector** (`upsert`/`update`/`delete` keyed on `id`).
- [ ] **Table is in the Postgres publication.** Absent = never syncs down.
- [ ] **Permissions are JWT-derived server-side** — the client passes no parameters.
- [ ] **On-demand streams registered.** **The stream name is not the table name** — pass the
      `sync-streams.yaml` name (`user_cost_estimates` for table `cost_estimates`). Wrong
      name silently activates nothing.

## 6. Wiring an on-demand synced table

An always-on synced table is the same minus activation.

### 6.1 DataSource owns lazy activation

Activation binds to the **subscription lifecycle**, not to construction — the table is
synced only while something watches. Write it once per data source as a private
`Stream<T> _watchWithSyncStream<T>({sql, parameters, mapRows, dedupe})`; each public method
supplies only its query and row projection. Build it with `Stream.multi` so activation runs
per-listener, and hold these invariants:

- **Set `controller.onCancel` before the first `await`.** Dart does not replay a cancel that
  fires before the callback is assigned, so a cancel racing activation would leak the handle.
- **Release through a helper that nulls the field before calling `unsubscribe()`** —
  `unsubscribe()` is not idempotent, and both `onCancel` and the post-await checks can reach it.
- **Re-check `listenerCancelled || !controller.hasListener` after every await** — after
  `syncStream()` returns, and again after wiring the inner subscription. Cancelled → release
  and return.
- **A `syncStream()` throw is terminal.** Catch it, `controller.addError(...)`, then
  `controller.close()`. Never leave a live stream that can never emit.
- **`onCancel` cancels the inner `watch()` subscription first, then releases the handle**,
  and nulls both fields.

**`dedupe`:** `watch()` re-fires on *any* change to a queried table, so a single-row watch
rebuilds an identical value when an unrelated row changes. Pass `true` for shapes with
value equality (one DTO, a scalar). Leave it off for `List<Dto>` — Dart compares lists by
identity, so it is a no-op that reads as protection.

> ⚠️ **Emptiness is not permission.** A server-side permission denial syncs no rows and
> `watch()` emits `[]` — indistinguishable from "none yet". Gate on the permission
> upstream, never on an empty stream.

### 6.2 RepositoryImpl — the error boundary

`Either` lives here and nowhere below. Reads: `.map` to entities in `Right`;
`.handleError` logs once (`AppLogger().tag(...)`) and maps to a domain `Failure`.
A `watch()` error is recoverable — map to `Left`, keep the stream alive. A `syncStream()`
activation failure is terminal — the DataSource already closed the stream, so that `Left`
is the last event and the UI must offer re-subscribe.
Writes: `try/catch`, `Right(null)` on success (= local+queued, §4), `Left` on a local error.

Reuse `code-data`'s exception→Failure mapping (timeout/socket/Postgrest → warning vs error;
unknown → `UnexpectedFailure`). **Reuse an existing `{Feature}Failure` — never invent one inline.**

### 6.3 Presentation & DI

- **Cubit/Bloc:** subscribe on init, emit per `Either`, **cancel on `close()`**. Never patch
  the list after a write.
- **DI:** `addLazySingleton` in the owning Modular module — `{feature}_module.dart`, or
  `{name}_library_module.dart` when shared across features (cost estimation lives in
  `lib/libraries/estimation/`).
- **Migrating an existing Supabase feature:** register the PowerSync DataSource alongside
  the request/response one; leave the repository bound to the old impl until the cutover PR.

## 7. SQLite encodings

Per [`schema.dart`](../../lib/libraries/powersync/models/schema.dart):

- **Booleans are integers.** Convert on both sides, in different places: reads in
  `Dto.fromRow` (`(row['is_locked'] as int? ?? 0) != 0`), writes at the insert
  (`e.isLocked ? 1 : 0`) — because `toJson`/`fromJson` stay the Supabase bool shape.
- **Timestamps are `text`.** Parse/format ISO strings yourself.
- **Numerics:** `Column.real` → `double`, `Column.integer` → `int`.
- **`id`** is added by PowerSync — don't redeclare it; do set it on insert.

## 8. Testing (see `write-tests`, `write-tests-mutation`)

Against [`FakePowerSyncDatabaseWrapper`](../../lib/libraries/powersync/testing/fake_powersync_database_wrapper.dart),
never the real DB:

- **Reads:** `fake.stubGetAll(sql, rows)`; `fake.emitWatch(sql, rows)` (seeds replay to late subscribers).
- **Errors:** `fake.emitWatchError(sql, err)` / `getAllError` / `executeError` / `syncStreamError`.
- **Writes:** assert `fake.executeCalls` holds the expected `(sql, parameters)` — verify bound params, not just the call.
- **Transactions:** `fake.writeTransactionCallCount`; inner `tx.execute()` calls still land in `executeCalls` in order. `writeTransactionError` fails before the callback runs.
- **Activation:** `fake.syncStreamCalls` contains the stream name after the first subscription.
- **Release:** after cancel, `fake.syncStreamUnsubscribes` contains it — exactly once.
- **Cancel-during-activation:** `listen()` then `cancel()` synchronously, then
  `await pumpEventQueue()` — asserts the handle acquired after the subscriber left is still released.
- `fake.reset()` between tests, `fake.dispose()` in teardown.

## Checklist

- [ ] Reads go through `watch()`; `getAll()` one-shots justified.
- [ ] DataSource returns DTOs and rethrows; no `Either` below the repository.
- [ ] RepositoryImpl maps to a reused `Failure`, logs once.
- [ ] Writes optimistic; server-acceptance-critical ones confirmed with the user (§4 gate).
- [ ] `syncStream` activates on first watch, releases once on cancel, survives a cancel racing activation.
- [ ] No permission inferred from an empty stream.
- [ ] Backend sync config asked for and reconciled (§5) — stream name and SELECTed columns confirmed, not guessed.
- [ ] DTO handles bool-as-int and text timestamps.
- [ ] Tests cover reactive + error + activation + release paths.
