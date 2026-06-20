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

**Relationship to `code-data`:** Same Clean-Architecture layering and the same
error-boundary rule (RULE_15: the DataSource always rethrows; the `RepositoryImpl`
logs+maps once). What changes is the *shape*: reads are reactive `Stream`s, writes
are optimistic local mutations. If the table is **not** in the PowerSync schema, use
`code-data` instead.

---

## 0. The seam you depend on

Features never touch `PowerSyncDatabase` directly. They depend on
[`PowerSyncDatabaseWrapper`](../../lib/libraries/powersync/interfaces/powersync_database_wrapper.dart),
which returns plain `List<Map<String, dynamic>>` rows so no sqlite/PowerSync types
leak above the data-source layer.

| Method | Use it for |
|--------|-----------|
| `Stream<List<Map>> watch(sql, {parameters, throttle})` | **Default read.** Live result set; re-emits on every local *or* synced change. |
| `Future<List<Map>> getAll(sql, [parameters])` | **One-shot read only** — validation lookups, export snapshots, reading a value inside a write flow. |
| `Future<void> execute(sql, [parameters])` | **Write.** Applies to local SQLite immediately, queues for background upload. |
| `Future<void> syncStream(name)` | **On-demand sync** — activate an on-demand stream when the feature is entered. |

The seam intentionally starts small and **grows as features require it**. If you need
surface it lacks (`writeTransaction` for atomic multi-statement writes, a project-owned
sync-status value object), add it to the interface, the `...WrapperImpl`, and
`FakePowerSyncDatabaseWrapper` in one change with a test — don't reach around the seam.

The wrapper, connector, manager, and DB lifecycle are **already wired** in
[`powersync_module.dart`](../../lib/libraries/powersync/powersync_module.dart). You
inject `PowerSyncDatabaseWrapper` into your DataSource; you do **not** open the DB,
manage `connect()`, or touch the connector.

---

## 1. The two rules that drive every decision

1. **Read reactively by default.** Anything rendered on screen (lists, detail views,
   counts) reads through `watch()` so the UI stays live as sync arrives. Reach for
   `getAll()` only when the read is genuinely one-shot.
2. **`watch()` is the source of truth — including after a write.** After `execute()`,
   do **not** re-fetch or optimistically patch UI state by hand. The local write makes
   every relevant `watch()` stream re-emit at once; let the stream carry the new state.

---

## 2. Class shapes

| Class | Naming | Returns | Notes |
|-------|--------|---------|-------|
| **DataSource** (interface) | `{Noun}DataSource` | reactive `Stream` / `Future` of **DTOs or raw rows** | Explicit method names. **No `Either` here.** Always rethrows. |
| **PowerSync DataSource** (impl) | `PowerSync{Noun}DataSource` | same | Talks to `PowerSyncDatabaseWrapper`. Owns on-demand stream activation (§5). |
| **RepositoryImpl** | `{Noun}RepositoryImpl` | `Stream<Either<Failure, T>>` (reads) / `Future<Either<Failure, void>>` (writes) | **Error boundary.** Maps stream/exec errors to `Failure`, logs once. |
| **DTO** | `{Noun}Dto` | — | Row `Map` ↔ Entity. Mind sqlite encodings (§6). |

**Read pipeline:** `wrapper.watch(sql)` → DataSource maps rows → `Stream<List<Dto>>`
(rethrows) → RepositoryImpl `.map(toEntity)` + `.handleError(log & map to Failure)` →
`Stream<Either<Failure, List<Entity>>>` → Cubit/Bloc **subscribes** (does not call once)
and cancels on close.

**Write pipeline:** Cubit → `repository.create(entity)` → DataSource `execute(insert)`
(rethrows local failures) → RepositoryImpl wraps in `try/catch` → `Either`. The UI change
arrives back through the existing `watch()` stream — never patch the list by hand.

**One feature, many use cases → one shared instance.** DataSource and RepositoryImpl are
stateless (they hold only the wrapper). Two UIs over the same table (e.g. "recent" vs
"full list") share the same `addLazySingleton` instance and differ only by query — expose
intention-revealing methods (`watchRecent(projectId, {limit})` vs `watchAll(projectId)`),
not separate instances. The divergence lives in separate Cubits, not the data layer.

---

## 3. Writes — optimistic, local-first

`execute()` writes to local SQLite immediately (so `watch()` re-emits at once) and
**queues** the row for background upload by the connector.

- **Repository write success means "persisted locally + queued for upload" — NOT
  "accepted by the server."** The synchronous `Future<Either<Failure, void>>` can only
  surface a *local* failure (SQLite/constraint).
- **Server rejection is asynchronous.** The connector handles an RLS denial (Postgres
  `42501`) by completing the CRUD transaction to unblock the queue; the local optimistic
  row stays in SQLite. Surfacing that to the user happens later via the conflict channel
  (`CA-660`), not via this return value. See
  [`supabase_powersync_connector.dart`](../../lib/libraries/powersync/data/connectors/supabase_powersync_connector.dart).
- **Always write IDs/timestamps explicitly** — PowerSync does not generate them on the
  local row. Generate UUIDs client-side and set `created_at`/`updated_at` yourself.

> 🛑 **Decision gate — do not guess.** When a write's *server acceptance* matters to the
> UX (e.g. locking a cost estimate, anything where showing "saved" before the server
> agrees is wrong), **stop and ask the user** how confirmation/conflict should be handled
> before coding. The optimistic default is correct for most edits; it is not universal.

---

## 4. Backend config (separate repo) — invariants & checklist

The PowerSync sync rules live in the **backend repo**, not here. This skill does not
reproduce the YAML (it would drift). When you add or change a synced table, reconcile
these invariants with the backend before the feature can work:

- [ ] **Schema ↔ stream-SELECT parity.** Every column the local `schema.dart` `Table`
      declares must be SELECTed by the corresponding `sync-streams.yaml` stream, with
      matching names/types. **Mismatches cause silent data loss** — no error, just
      missing/blank columns.
- [ ] **RLS mirrors the connector.** The connector uploads via `upsert`/`update`/`delete`
      keyed on `id`. Row-Level-Security policies must permit exactly those operations for
      the authenticated user, or uploads fail (a `42501` denial is treated as permanent).
- [ ] **Table is in the Postgres publication** PowerSync replicates from. A table absent
      from the publication never syncs down.
- [ ] **Permissions are JWT-derived, server-side.** Membership and feature permissions
      (e.g. `get_cost_estimations`) are resolved from JWT claims in the sync rules — the
      client passes **no** parameters for them. Confirm the claim exists in the issued JWT.
- [ ] **On-demand streams are registered** in the sync rules so `syncStream(name)` from
      the client activates them.

---

## 5. Wiring an on-demand synced table

> **Names below are illustrative.** `cost_estimates` / `CostEstimate` /
> `get_cost_estimations` are a running example — substitute your ticket's table, entity,
> permission, and method names. The structure is identical for every synced table. A
> *standard* (always-on) synced table is the same minus the activation step (§5.1).

### 5.1 DataSource owns on-demand activation — lazily

Activation is triggered on the **first `watch()` subscription** and released on cancel, so
the stream only syncs while something is watching. Sync mechanics stay behind the seam;
the repository and Cubit stay unaware. The non-obvious part is binding activation to the
subscription lifecycle via `Stream.multi`:

```dart
@override
Stream<List<CostEstimateDto>> watchByProject(String projectId) {
  return Stream<List<CostEstimateDto>>.multi((controller) async {
    await _wrapper.syncStream('cost_estimates');        // JWT-gated; no client params
    final sub = _wrapper
        .watch(_byProjectSql, parameters: [projectId])  // watch() stays single source of truth
        .map((rows) => rows.map(CostEstimateDto.fromRow).toList())
        .listen(controller.add, onError: controller.addError, onDone: controller.close);
    controller.onCancel = sub.cancel;                   // release on cancel — no leak
  });
}
```

> ⚠️ **Footgun — emptiness is not permission.** If `get_cost_estimations` is denied
> server-side, no rows sync and `watch()` simply emits `[]` — indistinguishable from
> "no estimates yet" at the data layer. **Never infer permission state from an empty
> stream.** Gate the feature on the permission upstream (auth/permissions), not on emptiness.

### 5.2 RepositoryImpl — the error boundary

`Either` lives here and nowhere below. Reads: `.map` DTOs → entities wrapped in `Right`;
`.handleError` logs once (`AppLogger().tag(...)`) and maps to a domain `Failure` — convert
`addError` into a `Left` rather than killing the stream where the UX should recover.
Writes: `try/catch` around the DataSource call, `Right(null)` on success (= local+queued,
**not** server-accepted, §3), `Left(Failure)` on a caught local error logged as `warning`.

Reuse the same exception→Failure mapping as `code-data` (timeout/socket/Postgrest →
warning vs error; unknown → `UnexpectedFailure`). **Reuse an existing `{Feature}Failure`
case — never invent one inline.**

### 5.3 Presentation & DI

- **Cubit/Bloc:** subscribe to `repository.watchByProject(...)` on init, emit state per
  `Either`, **cancel the subscription on `close()`**. Writes call `repository.create(...)`;
  the UI updates via the same watch stream — do not manually patch the list.
- **DI:** bind both as `addLazySingleton` in the feature's Modular module, injecting the
  already-exported `PowerSyncDatabaseWrapper` into the DataSource and the DataSource into
  the RepositoryImpl.

---

## 6. DTO / sqlite encoding notes

Rows are `Map<String, dynamic>` from SQLite. Watch the encodings declared in
[`schema.dart`](../../lib/libraries/powersync/models/schema.dart):

- **Booleans are integers.** `is_locked`: `0` = false, `1` = true. Convert in the DTO.
- **Timestamps are `text`.** Parse/format ISO strings yourself.
- **Numerics:** `Column.real` → `double`, `Column.integer` → `int`. Don't assume.
- **`id`** is added automatically by PowerSync — don't redeclare it; do set it on insert.

---

## 7. Testing (cross-link: `write-tests`, `write-tests-mutation`)

Test the data layer against
[`FakePowerSyncDatabaseWrapper`](../../lib/libraries/powersync/testing/fake_powersync_database_wrapper.dart)
— never the real DB. General test structure, naming, and mutation-coverage rules come
from the `write-tests` skills; the PowerSync-specific moves are:

- **One-shot reads:** `fake.stubGetAll(sql, rows)`, then assert the mapped result.
- **Reactive reads:** `fake.emitWatch(sql, rows)` to drive emissions; assert the Cubit/
  repository reacts. Seeded values replay to late subscribers (mirrors real `watch`).
- **Error mapping:** `fake.emitWatchError(sql, err)` / `fake.getAllError` / `fake.executeError`
  to prove the RepositoryImpl maps to the right `Failure`.
- **Write assertions:** after a write, assert `fake.executeCalls` contains the expected
  `(sql, parameters)` — verify the SQL and bound params, not just that a call happened.
- **Lazy on-demand activation:** assert `syncStream(...)` is called on first `watch`
  subscription and that the watch controller is released on cancel (no leak).
- Use `fake.reset()` between tests and `fake.dispose()` in teardown to close controllers.

---

## Checklist before you call it done

- [ ] Reads go through `watch()` (one-shots justified for `getAll()`).
- [ ] DataSource returns DTOs/rows and **rethrows**; no `Either` below the repository.
- [ ] RepositoryImpl maps errors to a reused `Failure`, logs once (warning vs error).
- [ ] Writes are optimistic; success ≠ server-accepted is documented/handled; server-
      acceptance-critical writes were confirmed with the user (§3 gate).
- [ ] On-demand `syncStream` activates lazily on first watch and releases on cancel.
- [ ] No permission inferred from empty streams.
- [ ] Backend invariants (§4) reconciled with the backend repo.
- [ ] DTO handles sqlite encodings (bool-as-int, text timestamps).
- [ ] Tests use `FakePowerSyncDatabaseWrapper`; reactive + error + activation paths covered.
