# PowerSync Integration

**Status as of 2026-08-15.** This is the handover doc referenced (but not previously
written) by [CA-643](https://ripplearc.youtrack.cloud/issue/CA-643) as the "PowerSync
Integration Wiki." It documents what actually exists today — merged code, open PRs, and
real subtask status — not a design proposal. Branch/PR state changes fast in this stack;
treat anything below tagged with a date as a snapshot, and re-verify before relying on it
for a merge decision.

**Related:** [CA-643](https://ripplearc.youtrack.cloud/issue/CA-643) (parent) ·
[CA-918](https://ripplearc.youtrack.cloud/issue/CA-918) (this spike) ·
`skills/code-data-powersync/SKILL.md` (agentic-coding skill for writing PowerSync data
layers — currently on an unmerged branch, see [Open Findings](#open-findings-and-gaps))

---

## Table of Contents

1. [Architecture](#architecture)
2. [What's Merged vs What's Still on the Stack](#whats-merged-vs-whats-still-on-the-stack)
3. [CA-643 Subtask Status](#ca-643-subtask-status)
4. [The Seam: Manager / Wrapper / Data Source](#the-seam-manager--wrapper--data-source)
5. [On-Demand Sync-Stream Lifecycle](#on-demand-sync-stream-lifecycle)
6. [Auth-Driven Connect / Disconnect](#auth-driven-connect--disconnect)
7. [Local Development Environment](#local-development-environment)
8. [Backend Config Invariants](#backend-config-invariants)
9. [Open Findings and Gaps](#open-findings-and-gaps)

---

## Architecture

```
Supabase Postgres  →  PowerSync Service  →  Flutter SDK (PowerSyncDatabase)  →  local SQLite
        ↑                                            │
        └──────────── upload queue (connector) ──────┘
```

- **Auth:** JWT-based via Supabase Auth. `SupabasePowerSyncConnector.fetchCredentials()`
  refreshes the Supabase session and hands PowerSync the access token.
- **Sync:** WAL replication, Sync Streams (**Edition 3**) — some streams auto-subscribe on
  connect (user profile, projects, memberships), others are on-demand, activated only
  while a feature is actively watching (cost estimates).
- **Writes:** optimistic and local-first. `execute()` commits to local SQLite immediately
  and queues the row for background upload; the connector drains the queue and applies it
  to Supabase. A write's `Future<Either<Failure, void>>` return means "persisted locally +
  queued," **not** "accepted by the server" — server rejection (RLS denial) is async and
  currently silent to the user (see [Open Findings](#open-findings-and-gaps)).
- **Conflict resolution:** server-authoritative. RLS denials (Postgres `42501`) are treated
  as permanent — the connector completes the transaction to unblock the queue rather than
  retrying — while every other upload error is treated as transient and rethrown so
  PowerSync retries automatically.

---

## What's Merged vs What's Still on the Stack

### Merged (on `main`)

| PR | Ticket | What it added |
|---|---|---|
| [#283](https://github.com/ripplearc/construculator-app/pull/283) | CA-645 | `lib/libraries/powersync/models/schema.dart` — client-side SQLite schema |
| [#284](https://github.com/ripplearc/construculator-app/pull/284) | CA-646 | `lib/libraries/powersync/data/connectors/supabase_powersync_connector.dart`, `powersync_module.dart` (connector binding only), `testing/fake_powersync_database.dart` |

On `main` today, `PowerSyncModule` only binds `PowerSyncBackendConnector`. There is no
`PowerSyncDatabase`, `PowerSyncDatabaseWrapper`, or `PowerSyncManager` yet — those three
arrive via the open stack below.

> **Branches `feat/init-powersync-flutter` and `feat/powersync-configs` are not stale** —
> they're the (undeleted) source branches for #283 and #284 above, already merged. Ignore
> them when reasoning about what's still open.

### Open stack (unmerged, as of 2026-08-15)

The ticket that spawned this doc described a "4-PR chain." It's actually **five** open
PRs — the skill-doc PR contributes no `lib/` code, which makes it easy to miss as a
distinct link:

```
main
 └─ feat/wire-powersync                        PR #364  CA-648  OPEN
     └─ feat/power-sync-wrappers               PR #367  CA-648  OPEN
         └─ skills/create-agentic-skill-for-powersync   PR #368  CA-671  OPEN (docs only)
             └─ feat/powersync_cost_estimate_data_source  PR #405  "migration PR1"  OPEN
                 └─ feat/watch_estimation_by_id  PR #529  "PR2"  OPEN
```

PR #529 was not mentioned in the ticket that spawned this doc — it's already stacked on
top of #405 and will land next; flagging it here so it isn't a surprise.

| PR | Base ← Head | Adds |
|---|---|---|
| [#364](https://github.com/ripplearc/construculator-app/pull/364) | `main` ← `feat/wire-powersync` | Opens the local DB (`open_powersync_database.dart`), `PowerSyncManager` interface + impl (auth-driven connect/disconnect), threads `powerSyncDatabase` through `AppBootstrap` |
| [#367](https://github.com/ripplearc/construculator-app/pull/367) | `feat/wire-powersync` ← `feat/power-sync-wrappers` | `PowerSyncDatabaseWrapper` interface + impl + fake (`getAll`/`watch`/`execute`/`writeTransaction`/`syncStream`) |
| [#368](https://github.com/ripplearc/construculator-app/pull/368) | `feat/power-sync-wrappers` ← `skills/create-agentic-skill-for-powersync` | `skills/code-data-powersync/SKILL.md` — the agentic-coding skill for writing PowerSync data layers |
| [#405](https://github.com/ripplearc/construculator-app/pull/405) | `skills/create-agentic-skill-for-powersync` ← `feat/powersync_cost_estimate_data_source` | First consumer: `PowerSyncCostEstimationDataSource(Impl)`, `CostEstimateDto`, DI registration |
| [#529](https://github.com/ripplearc/construculator-app/pull/529) | `feat/powersync_cost_estimate_data_source` ← `feat/watch_estimation_by_id` | `watchEstimationById` |

**Note:** #405 registers `PowerSyncCostEstimationDataSource` in DI, but
`CostEstimationRepositoryImpl` still consumes the existing Supabase-direct
`CostEstimationDataSource` — the PowerSync-backed read path is wired but not yet consumed
anywhere. That switchover is presumably a later PR in the stack.

### Does this still work on Flutter 3.44 / current coreui?

The ticket that spawned this doc flagged these branches as predating the Flutter 3.44 SDK
upgrade (CA-805) by roughly 100 commits — a real risk if true, since `a108666f9` (the
3.44 upgrade) and `d0d5878c2` (CA-825, the deprecated-API migration that followed it) both
landed on `main` well after this stack was cut.

**As verified today (2026-08-15), that's no longer the case.** All five branches were
freshly rebased onto current `main` tip — `git merge-base main origin/feat/wire-powersync`
resolves to `main`'s current HEAD (`ae3979288`), i.e. **0 commits behind**, and both the
3.44 upgrade and the CA-825 migration commits are confirmed ancestors of the stack. Whether
this rebase was intentional prep for handover or coincidental, it means the SDK-drift
concern is currently moot — but re-verify (`git merge-base --is-ancestor <main-tip>
origin/<branch>`) before relying on it, since these branches can drift out of date again at
any point.

---

## CA-643 Subtask Status

Real Stage as pulled from YouTrack today, not the ticket text:

| Ticket | Summary | Stage | Assignee | Points | Repo evidence |
|---|---|---|---|---|---|
| [CA-644](https://ripplearc.youtrack.cloud/issue/CA-644) | Local PowerSync dev environment | **Review** | Unassigned | 2 | No PR in this repo — Docker/YAML config lives in the backend repo, unverified here |
| [CA-645](https://ripplearc.youtrack.cloud/issue/CA-645) | Flutter schema, auto-table creation | **Review** | Unassigned | 2 | **Merged** — PR #283 |
| [CA-646](https://ripplearc.youtrack.cloud/issue/CA-646) | Backend connector, RLS error handling | **Review** | Unassigned | 2 | **Merged** — PR #284 |
| [CA-647](https://ripplearc.youtrack.cloud/issue/CA-647) | Sync Streams for core entities | **Review** | Unassigned | 2 | No PR in this repo — sync-stream YAML lives in the backend repo, unverified here |
| [CA-648](https://ripplearc.youtrack.cloud/issue/CA-648) | On-demand Sync Stream, cost estimates | **Review** | Unassigned | 0 | Open — PRs #364, #367, #405 (see above); [CA-917](https://ripplearc.youtrack.cloud/issue/CA-917) tracks a non-blocking `pubspec.yaml` nit on #367, informally resolved (see below) |

All five sit at Stage=Review and are unassigned — none have progressed further despite
CA-645/CA-646's code already being on `main`. Interpretation: the *code* for CA-645/646
landed, but nobody moved the tickets past Review — treat the Stage field as stale for
those two, not as a signal the work is undone. CA-644 and CA-647 genuinely have no
corresponding code in *this* repo to point to — their deliverables (Docker compose config,
`sync-config.yaml` stream definitions) live in the backend repo referenced by the parent
ticket, which this spike did not have access to audit.

**CA-917, tracking PR #367's `pubspec.yaml` change, reads as informally resolved.** A
reviewer flagged (2026-06-30) that PR #367 promotes `sqlite_async` from a transitive to a
direct `pubspec.yaml` dependency (needed because `powersync_database_wrapper_impl.dart`
imports `SqliteWriteContext`), which violates the project convention of leaving
`pubspec.yaml`/`pubspec.lock` untouched in feature branches, and offered two options: (a)
accept the dependency promotion as impl-layer scaffolding, or (b) change
`writeTransaction`'s signature to avoid the SDK import entirely. What actually happened is
a hybrid, not a pick of either option outright: a later commit (R2, "improve nitss") added
a `_WriteContextAdapter` closure so the `sqlite_async` type no longer leaks into the
repository/interface layer above the impl — but it never touched `pubspec.yaml`, so
`sqlite_async: ^0.13.1` remains a direct dependency today, unchanged since R1. The nit was
flagged 🍊 (non-blocking), and that same review was `APPROVED`; PR #367 has since collected
a second `APPROVED` review (2026-08-19) with the pubspec change still in place. No explicit
team decision is recorded, but two approvals with the dependency promotion left standing is
the closest thing to one — treat CA-917 as informally accepted via option (a) rather than
as a blocker still awaiting a call.

---

## The Seam: Manager / Wrapper / Data Source

Three layers sit between feature code and the native PowerSync SDK, each with a distinct
job. None of them are on `main` yet except the module shell — they arrive via PRs #364 and
#367.

| Layer | File | Owns |
|---|---|---|
| **Manager** | `powersync_manager.dart` / `powersync_manager_impl.dart` | Global connect/disconnect lifecycle, driven by auth events |
| **Wrapper** | `powersync_database_wrapper.dart` / `_impl.dart` | Per-call seam (`getAll`/`watch`/`execute`/`writeTransaction`/`syncStream`) returning plain `Map` rows — no PowerSync/sqlite types leak above this layer |
| **Data source** | e.g. `powersync_cost_estimation_data_source_impl.dart` | Per-feature on-demand sync-stream activation, tied to `watch()` subscription lifetime |

```dart
abstract class PowerSyncManager {
  PowerSyncDatabase get database;
  Future<void> connect();
  Future<void> disconnectAndClear();
}
```

```dart
abstract class PowerSyncDatabaseWrapper {
  Future<List<Map<String, dynamic>>> getAll(String sql, [List<Object?> parameters = const []]);
  Stream<List<Map<String, dynamic>>> watch(String sql, {List<Object?> parameters = const [], Duration throttle = kDefaultWatchThrottle});
  Future<void> execute(String sql, [List<Object?> parameters = const []]);
  Future<T> writeTransaction<T>(Future<T> Function(WriteContext tx) action);
  Future<SyncStreamHandle> syncStream(String name);
}

abstract class SyncStreamHandle {
  void unsubscribe();
}
```

`PowerSyncManagerImpl` is registered with `addSingleton` (not lazy) specifically so it's
instantiated eagerly at app start and begins listening to auth events without any caller
needing to resolve it — nothing calls `.connect()`/`.disconnectAndClear()` on it directly
from feature code; it drives itself. Everything else — `PowerSyncDatabase`,
`PowerSyncDatabaseWrapper`, feature data sources — is a normal `addLazySingleton` consumer.

**These two lifecycles are independent, layered on the same already-open database:** the
manager owns the *global* connection (does the app talk to the PowerSync service at all
right now), while `syncStream()`/`SyncStreamHandle.unsubscribe()` in the wrapper owns
*per-feature* activation of individual on-demand streams. A feature can be actively
watching data while the manager is mid-reconnect, and disconnecting the manager doesn't by
itself release any feature's sync-stream handle.

---

## On-Demand Sync-Stream Lifecycle

This was the ticket's central open question: *"How does an on-demand sync stream activate
and deactivate, and where is `SyncStreamHandle.unsubscribe()` supposed to be called?"*

**Answer:** activation is tied to `watch()` subscription lifetime, owned entirely by the
feature data source — not the manager, not the wrapper. `PowerSyncCostEstimationDataSourceImpl.watchEstimations()`
(PR #405) is the concrete, already-correct reference implementation:

```dart
Stream<List<CostEstimateDto>> watchEstimations({required String projectId, ...}) {
  return Stream<List<CostEstimateDto>>.multi((controller) async {
    SyncStreamHandle? handle;
    StreamSubscription<List<CostEstimateDto>>? subscription;
    var listenerCancelled = false;

    Future<void> releaseHandle() async {
      final currentHandle = handle;
      handle = null;
      currentHandle?.unsubscribe();
    }

    // Registered BEFORE the await below — closes the cancel-during-activation race.
    controller.onCancel = () async {
      listenerCancelled = true;
      await subscription?.cancel();
      subscription = null;
      await releaseHandle();
    };

    try {
      handle = await _wrapper.syncStream(_syncStreamName);
    } catch (error, stackTrace) {
      controller.addError(error, stackTrace);
      await controller.close();
      return;
    }

    if (listenerCancelled || !controller.hasListener) {
      await releaseHandle(); // cancelled while syncStream() was still pending
      return;
    }

    subscription = _wrapper
        .watch(sql, parameters: parameters)
        .map((rows) => rows.map(CostEstimateDto.fromRow).toList())
        .listen(controller.add, onError: controller.addError, onDone: controller.close);

    if (listenerCancelled || !controller.hasListener) {
      await subscription?.cancel();
      subscription = null;
      await releaseHandle();
    }
  });
}
```

Sequence: on the **first** listener attach, `syncStream(name)` activates the named stream
server-side (JWT-gated — no client params) and returns a handle. `watch()` then becomes
the source of truth for local data. On **cancel**, the watch subscription is cancelled and
`handle.unsubscribe()` releases the on-demand stream — so it only stays active while
something is actually watching it.

### The skill doc's teaching example now matches this

`skills/code-data-powersync/SKILL.md` (PR #368, still open) teaches this exact pattern to
every future implementer. As of review round R3 (2026-07-09), reviewer `ripplearcgit` had
flagged **two open 🔴 findings** against the worked example:

1. `controller.onCancel` in the SKILL.md example was assigned **after** the `await
   _wrapper.syncStream(...)` call, not before. If the subscriber cancels while that await
   is still pending, the cancel fires before `onCancel` is set — Dart does not retroactively
   invoke a handler assigned after the cancel already happened — so both the sync-stream
   handle and the watch subscription leak. Reviewer reproduced this directly against
   `Stream.multi` (Dart 3.29.2) to confirm.
2. The example's `await _wrapper.syncStream(...)` wasn't wrapped in try/catch, so a throw
   (JWT denial, no network) escaped as an unhandled Zone exception instead of reaching
   `controller.addError` — contradicting the skill's own testing guidance a few sections
   later, which asserts that exact propagation path.

**Both were fixed the same day**, in commit `ea326af25` ("R3: fix: cancel-before-activation
race and unhandled syncStream() throw in on-demand example"): `onCancel` is now registered
synchronously before the `syncStream()` await (with a `cancelled` flag checked once it
resolves, releasing the handle immediately if a cancel raced it), and the `syncStream()`
call is wrapped in try/catch so a throw surfaces via `controller.addError` instead of
escaping as an unhandled exception. The example now matches the production code above, and
is safe to copy as-is.

---

## Auth-Driven Connect / Disconnect

**No code calls `powerSyncManager.connect()` or `.disconnectAndClear()` directly from a
sign-in/sign-out code path.** The integration is event-driven, via the Supabase auth
stream:

1. `AuthManagerImpl.logout()` calls `SupabaseWrapper.signOut()` → the Supabase SDK's own
   `auth.signOut()`. `AuthManagerImpl` has no PowerSync awareness at all.
2. That triggers `SupabaseWrapper.onAuthStateChange` to emit `AuthChangeEvent.signedOut`.
3. **Two independent listeners** react to the same stream, each set up in its own
   constructor, unaware of each other:
   - `AuthManagerImpl._initAuthListener()` (merged, `main`) — updates the app's own
     `AuthNotifierController` state.
   - `PowerSyncManagerImpl._initAuthListener()` (PR #364) — on `signedIn`/`initialSession`
     with a session → `connect()`. On `signedOut` → `disconnectAndClear()`. Token refreshes
     and other events are ignored (the connector refreshes credentials on demand). If the
     app launches with an already-restored session, `connect()` fires immediately at
     construction rather than waiting for a fresh `signedIn` event.

**Sign-out with a different user on the same device:** `disconnectAndClear()` is called
with its default `clearLocal: true`, which wipes the locally synced SQLite data on
`signedOut`. The next `signedIn` for a different user triggers a fresh `connect()` and
resync — so there's no cross-user data leakage in local storage. This wasn't independently
tested end-to-end in this spike; it's a read of the implementation's intent, not a
verified behavior.

`FakeSupabaseWrapper._authStateController` was changed from `.broadcast()` to
`.broadcast(sync: true)` (PR #364) specifically so tests can assert on both listeners'
reactions synchronously, without draining the event loop. This is a shared-fake change —
it affects every other test using `FakeSupabaseWrapper`, not just PowerSync tests.

---

## Local Development Environment

Per [CA-644](https://ripplearc.youtrack.cloud/issue/CA-644) (Stage=Review, no code in this
repo to verify against): PowerSync runs as a Docker container alongside the local Supabase
stack, replicating from Postgres via WAL and issuing JWKS-verified credentials.

```
PS_POSTGRESQL_URI=postgresql://postgres:postgres@supabase_db:5432/postgres
PS_PORT=8080
PS_BACKEND_JWKS_URI=http://supabase_kong:8000/auth/v1/.well-known/jwks.json
PS_API_TOKEN=<generate-random-token>
```

Verify with `curl http://localhost:54321/auth/v1/.well-known/jwks.json` (non-empty keys
array) and `docker compose --file ./powersync/compose.yaml up -d`, then confirm the
PowerSync dashboard is reachable at `http://localhost:8080`.

**Known footgun:** `npx supabase@latest` is broken on darwin-arm64. Use `docker exec`
against the already-running local Supabase stack instead of the `npx` CLI wrapper.

This spike did not re-run or independently verify the local dev environment — the compose
file, `powersync.yaml`, and `sync-config.yaml` referenced by CA-644 were not found in this
repo, which matches the parent ticket's note that backend-side config lives outside it.
Confirming this setup still works is unfinished work, not something this doc can attest to.

---

## Backend Config Invariants

The PowerSync sync rules (`sync-streams.yaml`) live in the backend repo, not here — this
doc doesn't reproduce them (drift risk), but changing or adding a synced table requires
reconciling all of the following, per `skills/code-data-powersync/SKILL.md` §4:

- **Schema ↔ stream-SELECT parity.** Every column `schema.dart` declares for a table must
  be SELECTed by the matching backend stream, same names/types. A mismatch causes **silent
  data loss** — missing columns, no error.
- **RLS mirrors the connector.** The connector uploads via `upsert`/`update`/`delete` keyed
  on `id`; RLS policies must permit exactly those operations or uploads fail permanently
  (`42501`).
- **Table is in the Postgres publication** PowerSync replicates from — absence means it
  never syncs down, silently.
- **Permissions are JWT-derived, server-side** — the client passes no parameters for
  membership/permission checks; confirm the claim exists in the issued JWT.
- **On-demand streams are registered** in the backend sync rules so `syncStream(name)` from
  the client actually activates something.

None of these were independently verified against the backend repo in this spike.

---

## Open Findings and Gaps

Punch list of what's real vs. still needed before this stack can land, gathered from PR
review threads and direct code reading — not from re-running the app:

- **PR #368 (SKILL.md)'s 2 🔴 findings are fixed** (commit `ea326af25`, same-day fix) —
  the teaching example now matches the production implementation and is safe to copy — see
  [On-Demand Sync-Stream Lifecycle](#on-demand-sync-stream-lifecycle).
- **CA-917 (`sqlite_async` direct dependency on PR #367) reads as informally resolved,
  not blocking.** `sqlite_async` is still a direct `pubspec.yaml` dependency (added R1,
  unchanged since); the SDK-type leak into the repository layer was separately fixed via
  an adapter closure in R2. The flag was a non-blocking nit, and #367 has since collected
  two `APPROVED` reviews (2026-06-30, 2026-08-19) with the dependency promotion still in
  place — see [CA-643 Subtask Status](#ca-643-subtask-status).
- **`CostEstimationRepositoryImpl` doesn't consume `PowerSyncCostEstimationDataSource` yet**
  (PR #405) — it's registered in DI but the repository still reads through the Supabase-
  direct data source. The switchover PR wasn't found in the current stack.
- **RLS-denial conflicts are silent to the user.** `SupabasePowerSyncConnector` already
  distinguishes permanent RLS denials from transient errors correctly, but surfacing that
  to the UI is an explicit `TODO: [CA-660]` — not yet implemented.
- **CA-644 and CA-647** (local dev environment, core-entity sync streams) have no
  corresponding PR in this repo and weren't independently verified — their deliverables
  live in the backend repo.
- **PR #529** (`watchEstimationById`) is already stacked on top of #405 and will need to be
  accounted for in any plan to land this stack, even though it wasn't part of this ticket's
  original scope.
