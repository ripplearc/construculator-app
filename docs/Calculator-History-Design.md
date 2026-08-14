# Calculator History (`previousSessions`) — Integration Design

> Research doc for [CA-965](https://ripplearc.youtrack.cloud/issue/CA-965). `CalculatorPage` never wires `CoreDisplayArea.previousSessions` — CA-878 (2/2) wired everything else and left an explicit `TODO(CA-965)` at the call site. This doc is the "written recommendation covering archiving trigger, data model, and persistence approach" the ticket's acceptance criteria require, plus a fourth axis the ticket's Solution section also asks for: date-label formatting. **No application code is added by this ticket** — the recommendations below are implementation work for a follow-up ticket under CA-450.

---

## Table of Contents

1. [Overview](#overview)
2. [Archiving Trigger](#archiving-trigger)
3. [Data Model](#data-model)
4. [Persistence](#persistence)
5. [Date-Label Formatting](#date-label-formatting)
6. [Open Questions / Follow-Ups](#open-questions--follow-ups)

---

## Overview

`CoreDisplayArea` (coreui) accepts `previousSessions: List<CoreHistorySessionData>`, rendered only in the `DisplayAreaStage.expandedPrevious`/`fullScreen` stages: `expandedPrevious` teases just the most recent session, `fullScreen` lists all of them, each showing a `dateLabel`, its chips, and its final value. `CoreHistorySessionData` is a flat, presentation-only shape:

```dart
// coreui: lib/src/components/display_area/core_history_session_data.dart
class CoreHistorySessionData {
  final String dateLabel;                    // pre-formatted, e.g. "Today", "May 24, 2026"
  final List<CoreCalculatorChip> chipsList;
  final String value;
}
```

`CalculatorState` (`lib/features/calculator/presentation/bloc/calculator_bloc/calculator_state.dart`) has no session/history concept today — `completedChips`/`resultChip` only ever describe the *in-progress* calculation, and both `CalculatorBloc._onControlActioned` (`ControlAction.clearAll`) and `_onResetRequested` (wired to `CoreDisplayArea.onClose`) discard that state unconditionally via `emit(CalculatorState.initial())`. There is no existing design for history anywhere — not in CA-861, not in the estimation module design doc, not in Figma. This doc fills that gap.

---

## Archiving Trigger

**Recommendation: archive a session at the existing reset call sites — `ControlAction.clearAll` and `CalculatorResetRequested` — but only when `state.resultChip != null`.**

Both call sites already exist in `CalculatorBloc` (`lib/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart`) and already represent "this calculation is over, throw away in-progress state":

- `_onControlActioned`, `ControlAction.clearAll` — user pressed the keyboard's Clear key.
- `_onResetRequested` — fired from `CoreDisplayArea.onClose` (the X button) in `calculator_page.dart`.

Neither needs a new UI affordance; the archiving step is inserted *before* the existing `emit(CalculatorState.initial())` in each. The gate is `state.resultChip != null`: a session is only worth remembering if the user actually reached a computed result. Abandoned partial input (a few chips typed, then cleared with no result) is not archived — it isn't a "calculation" from the user's perspective and would just be noise in the history list.

This also means a session archives exactly once, at a single well-defined point, rather than needing a running "is this session dirty" flag — the reset call sites are already the only places `CalculatorState.initial()` is emitted.

---

## Data Model

**Recommendation: a small domain type distinct from `CoreHistorySessionData`, not `CoreHistorySessionData` itself.**

```dart
class CalculationSession {
  final DateTime completedAt;
  final List<CoreCalculatorChip> chips;
  final String resultValue;
}
```

`CoreHistorySessionData.dateLabel` is a plain `String`, not a `DateTime` — if a session's label were computed once at archive time and stored as text (e.g. `"Today"`), it would go stale the next day without a code path to refresh it. Storing `completedAt` as a real `DateTime` and deriving the label at render time (see [Date-Label Formatting](#date-label-formatting)) avoids that. The `chips`/`resultValue` fields carry over directly from `CalculatorState.completedChips` and `resultChip`/`resultValue` at the moment of archiving.

Mapping `CalculationSession → CoreHistorySessionData` is a pure, stateless conversion done wherever `previousSessions:` is built for `CoreDisplayArea` — not stored.

---

## Persistence

**Recommendation: a local repository backed by PowerSync, following the existing `cost_estimates` on-demand-sync-table pattern — not in-memory-per-page-instance.**

In-memory-only was the other option considered, and it doesn't actually satisfy the ticket's own framing ("in-memory-per-page-instance vs. a local data source/repository that survives app restart"): `CalculatorPage` builds `CalculatorBloc` fresh on every mount —

```dart
// calculator_page.dart
BlocProvider<CalculatorBloc>(create: (_) => CalculatorBloc(), ...)
```

— so in-memory state doesn't survive navigating away and back to the Calculator tab, let alone an app restart. An in-memory-only design would make the history panel appear to work in a demo (stay on the page, do a few calculations) and then empty itself the moment a real user leaves and returns, which is worse than not building it.

The app has no existing local-storage package (no Hive/sqflite/drift/isar/`shared_preferences`) — the only local-persistence mechanism already in use is **PowerSync** (`pubspec.yaml`, `powersync: 1.18.0`), and it already has a precedent for exactly this shape of data: an on-demand sync table, scoped to when the user is actually in the relevant feature —

```dart
// lib/libraries/powersync/models/schema.dart
// On-demand stream: call `db.syncStream('user_cost_estimates')` when the
// user enters the cost estimation feature. Membership and the
// `get_cost_estimations` permission are derived from the JWT server-side,
// so no parameters are passed from the client.
Table('cost_estimates', [...]),
```

A follow-up `calculator_sessions` table, synced on-demand only while the user is in the Calculator (mirroring `cost_estimates`), is the idiomatic path already established in this codebase, rather than introducing a second, unrelated local-storage mechanism just for this feature. A `CalculatorHistoryRepository` on top would follow the same interface → impl → PowerSync-backed data source shape every other repository in `lib/features/**`/`lib/libraries/**` already uses.

---

## Date-Label Formatting

**Recommendation: compute the label at render time from `CalculationSession.completedAt`, not at archive time — add a small helper, since none exists today.**

No relative-date ("Today"/"Yesterday") helper exists anywhere in this app or in coreui today:
- `DisplayFormatter.date` (`lib/libraries/formatting/display_formatter.dart`) only does absolute formatting (`DateFormat('MMM dd, yyyy')`).
- coreui's `core_date_range_sheet.dart`/`core_date_filter_chip.dart` only expose static labels (`todayLabel = 'Today'`) for quick-filter buttons, not date→label conversion.
- The showcase fixtures in `coreui/example/lib/screens/display_area_showcase_screen.dart` hardcode `dateLabel` strings directly (`'May 24, 2026'`, `'Yesterday'`) — they're static demo data, not a formatting spec.

The recommendation is a small day-diff helper (e.g. extending `DisplayFormatter`) that takes a `DateTime` and returns `"Today"` / `"Yesterday"` / an absolute date via the existing `DisplayFormatter.date` pattern for anything older, computed each time `previousSessions` is built for `CoreDisplayArea` — never stored — so a session archived "Today" correctly reads "Yesterday" the next time the panel renders, with no background job or invalidation needed. The app's l10n already has day-relative strings in a different context (`dateRangeSheetToday` etc. in `app_localizations_en.dart`); reuse those keys rather than hardcoding new English strings, so the label localizes for free.

---

## Open Questions / Follow-Ups

These are deliberately left for the follow-up implementation ticket, [CA-969](https://ripplearc.youtrack.cloud/issue/CA-969), not blockers for this design:

- Retention/cap on stored sessions (unbounded history vs. e.g. last N or last 30 days) — not specified by the ticket; needs a product call before the `calculator_sessions` schema is finalized.
- Per-user vs. per-project scoping of history, and whether it should sync across a user's devices (PowerSync would give this for free) or stay device-local — worth confirming against how `cost_estimates` scopes today before copying its pattern exactly.
- Exact `calculator_sessions` schema/columns and the `Failure`/error-mapping shape for `CalculatorHistoryRepository` — deferred to whoever implements it, following the existing repository pattern in `lib/features/**`.
