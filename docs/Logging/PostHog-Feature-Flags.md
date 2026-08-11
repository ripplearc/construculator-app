# PostHog Feature Flags — Integration Design

> Extracted/derived from the [PostHog Integration Guide](Posthog-Integration.md) §[Feature Flags](Posthog-Integration.md#feature-flags) per [CA-954](https://ripplearc.youtrack.cloud/issue/CA-954).
> That section covers *usage patterns* (rollout examples, best practices, the flag registry). This doc covers the *architecture*: evaluation model, targeting, wrapper boundary, fail-safe behavior, and testing — the design CA-955 (gate the Calculator module) implements against.

---

## Table of Contents

1. [Overview](#overview)
2. [Naming: PostHog Feature Flags vs. Compile-Time `FeatureFlags`](#naming-posthog-feature-flags-vs-compile-time-featureflags)
3. [Evaluation Model: Local Cache vs. Per-Call](#evaluation-model-local-cache-vs-per-call)
4. [Targeting Model](#targeting-model)
5. [Wrapper Boundary](#wrapper-boundary)
6. [Fail-Safe Behavior](#fail-safe-behavior)
7. [Testing Approach](#testing-approach)
8. [Open Questions / Follow-Ups](#open-questions--follow-ups)

---

## Overview

PostHog Feature Flags is a separate PostHog product from the analytics/event-capture surface CA-937 shipped (CA-941–946): flags are **runtime, SDK-evaluated**, and support boolean toggles, multivariate values, JSON payloads, rollout percentages, and cohort/property targeting — all changeable from the PostHog dashboard without an app release.

This doc formalizes the design decisions the ticket's acceptance criteria require, ahead of CA-955 ("Gate the Calculator module behind a PostHog feature flag"), which is the first real consumer and is blocked on this doc landing. No code is added by this ticket — `FeatureFlagRepository`, wrapper extensions, and fakes described below are CA-955's (or a dedicated follow-up's) implementation work.

Only the `dev/fishfood` PostHog Cloud project exists today (CA-943), so any flag defined against this design is only usable/testable in that environment until qa/prod projects exist.

---

## Naming: PostHog Feature Flags vs. Compile-Time `FeatureFlags`

CA-925's High-Level Design ("Per-Flavor Feature Module Exclusion") introduces a **compile-time** `FeatureFlags.<feature>` mechanism — a Dart `const bool` sourced from a per-flavor JSON manifest via `bool.fromEnvironment`/`--dart-define-from-file`, gating a statement-level `if` so the AOT compiler const-folds and tree-shakes the dead branch (the same mechanism `kDebugMode` uses). That HLD is explicit that it is **not** this:

> "Not a runtime feature-flag or remote-config system. Runtime-toggleable features must by definition remain in the binary; that is the opposite problem."

PostHog Feature Flags — the subject of this doc — is exactly that "opposite problem": a runtime toggle whose code stays in the binary and whose value is fetched/cached from PostHog. Same words ("feature flag"), two unrelated mechanisms, different purposes. To keep them from being confused in code, tickets, or conversation:

| | PostHog Feature Flag (this doc) | CA-925 `FeatureFlags.<feature>` |
|---|---|---|
| **Example** | `calculator-enabled` | `FeatureFlags.calculator` |
| **Key format** | `kebab-case` string, PostHog dashboard-defined | `PascalCase` Dart static `const bool` |
| **Evaluated** | At runtime, via `PosthogWrapper`/`FeatureFlagRepository` | At compile time, AOT-folded |
| **Changing it** | PostHog dashboard, no app release | Requires a new binary build |
| **Purpose** | Gradual rollout, targeting, kill-switch, experiments | Per-flavor module exclusion (binary size / build-time capability removal) |
| **Code stays in binary?** | Yes — always shipped, gated at runtime | No — dead branch is tree-shaken out |

**Convention going forward:** always refer to PostHog flags by their dashboard key in `kebab-case` (e.g. `calculator-enabled`) and never as `FeatureFlags.X`, reserving that identifier exclusively for CA-925's compile-time mechanism. When both apply to the same feature area, name them so the distinction is legible at a glance (e.g. a PostHog flag `calculator-enabled` alongside a hypothetical compile-time `FeatureFlags.calculator` should be read as "is Calculator toggled on for this user" vs. "is Calculator's code present in this build" respectively).

---

## Evaluation Model: Local Cache vs. Per-Call

**Decision: local cache evaluation, reloaded at defined trigger points — not a per-call network round trip.**

`posthog_flutter`'s flag-read APIs (`getFeatureFlag`, `isFeatureEnabled`, `getFeatureFlagPayload`) read from a **client-side cache** populated by `reloadFeatureFlags()`; there is no synchronous per-call server evaluation mode in this SDK (that would require hitting PostHog's `/decide` endpoint directly on every read, bypassing the SDK — out of scope). This also matches the best practice already documented in the [Integration Guide](Posthog-Integration.md#feature-flag-best-practices): cache flag values, never evaluate inside `build()`.

**Reload triggers:**
1. App start, after `PosthogWrapper` initialization (i.e. after the existing `_isEnabled` single-gate is set — see [Wrapper Boundary](#wrapper-boundary)).
2. Immediately after every `identify()` call (login, registration, OTP verify — see [Targeting Model](#targeting-model)), since flags are evaluated against the current `distinct_id` and identifying a new person can change flag results.
3. Immediately after every `reset()` call (logout), for the same reason in the anonymous direction.

**Staleness tradeoff (explicit):** because evaluation reads a cache refreshed only at the triggers above, a flag toggled in the PostHog dashboard will not affect an already-running session until the next trigger fires (next app start, or next login/logout). This is acceptable for the intended use cases — gradual rollout, kill-switch, targeting — none of which require sub-second propagation. It would **not** be acceptable for a use case needing an in-session live update (e.g. a remote kill-switch that must take effect while the app is already open); if that need arises, it should call `reloadFeatureFlags()` explicitly at that point rather than changing the default trigger set.

---

## Targeting Model

**Decision: reuse the existing `distinct_id` identity, no new plumbing.**

CA-945 already wires `distinct_id` = Supabase `user.id` into the analytics layer via `AuthManagerImpl` (`lib/libraries/auth/auth_manager_impl.dart`, unmerged branch `CA-945-feat/identify-on-login-reset-on-logout` at time of writing):

```dart
// after login() / registerWithEmail() / OTP verify:
await _analyticsRepository.identify(userId: user.id, properties: const AnalyticsUserProperties());

// on logout():
await _analyticsRepository.reset();
```

PostHog feature flags are evaluated against the same `distinct_id` the SDK already tracks internally — no separate identity call is needed for flags. The only addition this design requires is triggering `reloadFeatureFlags()` alongside those existing `identify()`/`reset()` calls (see [Evaluation Model](#evaluation-model-local-cache-vs-per-call)), so cached flag state reflects the current identity promptly.

**Pre-login (anonymous) evaluation:** before the first `identify()` call, flags evaluate against PostHog's auto-generated anonymous `distinct_id`. This is acceptable for CA-955's use case (the Calculator entry point is inside `AppShellPage`, reached only post-login), but any future flag gating pre-login UI should evaluate anonymous targeting behavior explicitly before relying on it.

**Additional targeting/rollout axes (beyond `distinct_id`):** PostHog supports several rollout mechanisms that don't require any new identity plumbing. Confirmed directly against current PostHog docs, not assumed:

| Axis | Native support? | Notes |
|---|---|---|
| **Chained/triggering flags** | Yes — [flag dependencies](https://posthog.com/docs/feature-flags/dependencies) | A flag's release conditions can include "flag A equals true / variant X" as a condition type. PostHog resolves the dependency chain server-side on every evaluation of the dependent flag — no client-side orchestration needed. |
| **App-version gating** | Yes — semver release conditions | Release conditions support semver operators (`<`, `>=`, etc.) on `$app_version`. Mobile SDKs (including `posthog_flutter`) attach `$app_version` to every flag-evaluation request automatically via `setDefaultPersonProperties` (default `true`) — no manual property-setting required. |
| **Country diversion** | Yes — GeoIP | PostHog derives `$geoip_country_code` / `$geoip_country_name` from the request IP automatically; usable directly in release conditions with no `identify()`-time work. |
| **Locale (language) diversion** | No — needs a manual property | GeoIP gives geography, not the user's chosen app language. A flag that must target by *language* rather than country needs a custom person property (e.g. `app_locale`) set via `setPersonProperties()`, most naturally alongside the existing `identify()` call in `AuthManagerImpl`. Not implemented by this design — add it if/when a flag actually needs language-based targeting. |
| **Population-tier rollout (teamfood → dogfood → GA)** | Not a distinct primitive — same mechanism as regular rollout | PostHog has no built-in "stage" concept. [PostHog's own phased-rollout guidance](https://posthog.com/docs/feature-flags/phased-rollout) is to combine percentage rollout with cohorts — the same mechanism this doc already assumes for gradual rollout elsewhere. This isn't a gap to work around; it's the intended mechanism. |

None of the above change the wrapper/repository shape in [Wrapper Boundary](#wrapper-boundary) — they're all expressed as PostHog dashboard release conditions and stay transparent to `isFeatureEnabled()`/`getFeatureFlagVariant()` callers. The one actual to-do for a future flag author: if a flag needs locale targeting, set the `app_locale` person property explicitly; everything else in the table works out of the box.

---

## Wrapper Boundary

**Decision: extend the existing `PosthogWrapper`, not a new sibling wrapper — with a new `FeatureFlagRepository` on top, separate from `AnalyticsRepository`.**

The real (currently unmerged) `PosthogWrapper` already has a single gate (`_isEnabled`, set only when `initialize()` receives a non-empty API key) that every method checks before doing anything:

```dart
// lib/libraries/analytics/interfaces/posthog_wrapper.dart (existing, unmerged CA-941 (4/6))
abstract class PosthogWrapper {
  Future<void> initialize({required String apiKey, required String host, bool debug = false});
  Future<void> capture({required String eventName, Map<String, dynamic>? properties});
  Future<void> identify({required String userId, Map<String, dynamic>? userProperties});
  Future<void> reset();
  Future<void> setPersonProperties({Map<String, dynamic>? userProperties});
  Future<void> group({required String groupType, required String groupKey, Map<String, dynamic>? groupProperties});
}
```

Feature-flag reads use the same underlying `Posthog()` SDK singleton and should go through the same gate, so this design adds flag methods directly to `PosthogWrapper` (and its real/fake implementations) rather than standing up a parallel `PosthogFlagsWrapper`:

```dart
abstract class PosthogWrapper {
  // ...existing analytics methods...
  Future<void> reloadFeatureFlags();
  Future<bool?> isFeatureEnabled(String flagKey);
  Future<String?> getFeatureFlagVariant(String flagKey);
  Future<Map<String, dynamic>?> getFeatureFlagPayload(String flagKey);
}
```

`PosthogSdk` (the thinner, untestable boundary `PosthogWrapperImpl` delegates to) gets the matching pass-throughs to `Posthog()`'s native flag methods.

On top of the wrapper, a `FeatureFlagRepository` — kept separate from `AnalyticsRepository` (Single Responsibility; this split was already anticipated when CA-941 (1/6)'s commit message explicitly deferred it: *"FeatureFlagRepository intentionally excluded — Phase 4 scope, nothing implements or consumes it yet"*):

```dart
// lib/libraries/analytics/domain/repositories/feature_flag_repository.dart (new, not part of this ticket)
abstract class FeatureFlagRepository {
  Future<Either<Failure, bool?>> isFeatureEnabled(String featureFlagKey);
  Future<Either<Failure, String?>> getFeatureFlagVariant(String featureFlagKey);
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(String featureFlagKey);
  Future<Either<Failure, void>> reloadFeatureFlags();
}
```

This corrects the [Integration Guide](Posthog-Integration.md#domain-layer-feature-flag-repository-interface)'s existing sketch of the same interface, which predates the real `PosthogWrapper` shape (it assumed a `setup(config)`-style gate rather than the actual `initialize({apiKey, host, debug})` single-gate pattern) — the interface signatures agree, but its implementation must delegate to the wrapper shape above, not the doc's older illustration.

`FeatureFlagRepositoryImpl` follows the same delegation + error-mapping shape as `AnalyticsRepositoryImpl` (see [Fail-Safe Behavior](#fail-safe-behavior)).

---

## Fail-Safe Behavior

**Decision: fail closed. Every failure path returns `Right(null)`, never `Left`, never throws — and `null` is always treated as "flag off."**

This matches two existing precedents exactly:
- `NoOpAnalyticsRepository` (used when `ANALYTICS_ENABLED=false`): every method is a no-op returning `Right(null)`.
- `AnalyticsRepositoryImpl`'s per-call try/catch, mapping `TimeoutException`/`SocketException`/other exceptions to typed `Failure`s, logged via `AppLogger`, never thrown to callers.

Applied to flags:

| Scenario | Behavior |
|---|---|
| `ANALYTICS_ENABLED=false` | `NoOpFeatureFlagRepository` (new, mirrors `NoOpAnalyticsRepository`) — every method returns `Right(null)` immediately, no SDK interaction. |
| SDK call times out / throws | Caught in `FeatureFlagRepositoryImpl`, mapped to a typed failure and logged, but the method still resolves `Right(null)` to the caller — flag reads must never surface as a blocking error a screen has to handle. |
| Flag key not found in PostHog | SDK itself returns `null` for an unrecognized/unset key; propagated as `Right(null)`, same as any other "off" result. |

**Why `Right(null)` even on error, not `Left(Failure)`:** the ticket requires flag evaluation to "never block or change app behavior." A `Left` return forces every call site to branch on a `Failure` before it can even ask "is this feature on" — for something as low-stakes as a rollout gate, that adds handling burden without a corresponding benefit. Callers already need to treat `null` as "off" per the existing best-practice guidance in the [Integration Guide](Posthog-Integration.md#feature-flag-best-practices); folding failures into that same `null` path means one branch (`true` / not-`true`) instead of two. This is a deliberate default, not an oversight — CA-955 or later consumers may choose a different default (e.g. fail *open* for a flag whose absence is the riskier state) but must document that choice explicitly per-flag, same way the ticket requires.

---

## Testing Approach

No real network calls in tests — same fake-boundary pattern as the existing analytics tests:

- **`FakePosthogWrapper`** (existing, `lib/libraries/analytics/testing/fake_posthog_wrapper.dart`) gains recordable flag calls plus configurable return values, following its existing `errorToThrow` pattern used to simulate SDK failures:
  ```dart
  class FakePosthogWrapper implements PosthogWrapper {
    // ...existing recording fields...
    final Map<String, bool?> flagOverrides = {};
    Object? errorToThrow;

    @override
    Future<bool?> isFeatureEnabled(String flagKey) async {
      if (errorToThrow != null) throw errorToThrow!;
      return flagOverrides[flagKey];
    }
  }
  ```
- **`FakeFeatureFlagRepository`** (new, mirrors `FakeAnalyticsRepository`'s recording style) for BLoC/widget tests that need a feature-flag-gated repository without touching `PosthogWrapper` at all — same DI pattern as `Modular.get<AnalyticsRepository>()` swapped for a fake singleton in tests.
- BLoC/widget tests that need deterministic flag state inject `FakeFeatureFlagRepository` with a fixed value (`true`/`false`/`null`) — never `NoOpFeatureFlagRepository`, which is a production no-op, not a test double (same distinction already documented for `NoOpAnalyticsRepository`).
- Unit tests for `FeatureFlagRepositoryImpl`'s error-mapping inject `FakePosthogWrapper` with `errorToThrow` set, asserting the mapped `Failure` type and that the return value is still `Right(null)` (see [Fail-Safe Behavior](#fail-safe-behavior)).

---

## Open Questions / Follow-Ups

These are intentionally left for CA-955 or a later ticket, not blockers for this design:

- Exact `Failure` subtype(s) for flag-read errors — reuse `AnalyticsFailure`'s `AnalyticsErrorType` enum, or introduce a parallel `FeatureFlagFailure`/`FeatureFlagErrorType`? Either is consistent with this design; deferred to whoever implements `FeatureFlagRepositoryImpl`.
- `getFeatureFlagVariant`/`getFeatureFlagPayload` are specified above for completeness (matching the Integration Guide's existing interface sketch) but have no consumer yet — CA-955 only needs `isFeatureEnabled`. Fine to implement all four together or to stub the unused two until a real consumer exists; either is in scope for whoever builds `FeatureFlagRepositoryImpl`.
- Whether `reloadFeatureFlags()` triggers should also include app-foreground/resume (not just start + identify/reset) is left open — not needed for CA-955's always-visible-after-login entry point, worth revisiting if a future flag needs to react while the app is already foregrounded.
