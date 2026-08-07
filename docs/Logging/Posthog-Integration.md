# PostHog Integration Guide for Construculator App

**Related docs:**
- [PostHog Event Tracking Reference](PostHog-Event-Tracking.md) — event taxonomy, naming conventions, data safety rules
- [Analytics Future Features](Analytics-Future-Features.md) — planned analytics for upcoming features

---

## Table of Contents

1. [Overview](#overview)
2. [Terminology](#terminology)
3. [Architecture Integration](#architecture-integration)
4. [Installation & Setup](#installation--setup)
5. [Clean Architecture Implementation](#clean-architecture-implementation)
6. [Event Tracking Strategy](#event-tracking-strategy)
7. [Funnels & Analytics](#funnels--analytics)
8. [Feature Flags](#feature-flags)
9. [A/B Testing & Experiments](#ab-testing--experiments)
10. [Group Analytics (B2B)](#group-analytics-b2b)
11. [Dashboard Configuration](#dashboard-configuration)
12. [Testing Strategy](#testing-strategy)
13. [Migration & Rollout Plan](#migration--rollout-plan)
14. [Best Practices](#best-practices)
15. [PostHog Feature Flag Registry](#posthog-feature-flag-registry)
16. [Appendix](#appendix)

---

## Overview

### What is PostHog?

PostHog is an all-in-one product analytics platform that provides:
- **Product Analytics**: Event tracking, user behavior analysis, funnels, retention
- **Feature Flags**: Remote configuration and gradual rollouts
- **A/B Testing**: Experimentation with statistical significance
- **Session Replay**: Visual debugging and user journey analysis (opt-in; adds ~2 MB to app size)
- **Group Analytics**: B2B company-level tracking (paid add-on)
- **Surveys**: In-app user feedback collection

### Why PostHog for Construculator?

1. **All-in-one**: Consolidates analytics, feature flags, and experiments under one SDK
2. **Developer-friendly**: Clean Flutter SDK with typed APIs
3. **B2B Focus**: Group analytics for tracking organizations and projects
4. **Privacy-first**: GDPR-compliant, supports anonymization via `identifiedOnly` person profiles
5. **Cost-effective**: Generous free tier, predictable per-event pricing above it

---

## Terminology

| Term | Definition |
|------|------------|
| **Distinct ID** | PostHog's identifier for a user. Starts as an anonymous UUID; replaced with the app user ID after `identify()`. |
| **Person Profile** | A PostHog record for an identified user, storing user properties. Controlled by `personProfiles` (`identifiedOnly` avoids creating profiles for anonymous sessions). |
| **Event** | A timestamped action captured from the client via `capture()`. Carries an event name and optional property map. |
| **Feature Flag** | A remote boolean or multivariate toggle controlling feature availability without an app update. PostHog does not natively support flag-triggering-flag; implement conditional logic in code if needed. |
| **Experiment** | PostHog's term for a controlled study splitting users into control and variant groups to measure the causal impact of a change on a goal metric. |
| **A/B Test** | In this doc, synonymous with Experiment. Specifically a two-variant study (control vs. treatment). When PostHog says "A/B Experiment" it means the same structured study — not a loose comparison of configurations. |
| **Funnel** | A sequence of ordered events measuring what percentage of users complete each step toward a goal. |
| **Cohort** | A group of users defined by shared properties or behaviors, used for retention and segmentation analysis. |
| **Group** | An account-level entity (e.g., project or company) that events can be associated with, enabling B2B analytics. A user can belong to multiple groups of **different types** simultaneously (e.g., both a `project` group and a `company` group). |
| **Rollout** | Gradually increasing the percentage of users receiving a feature flag as confidence in stability grows. |
| **Session Replay** | Pixel-accurate playback of user interactions for debugging and UX research. Opt-in; increases app size by ~2 MB. |
| **Statistical Significance** | The threshold at which experiment results are unlikely to be due to chance. PostHog displays this automatically on Experiment dashboards. |

---

## Architecture Integration

### Integration Principles

Following Construculator's clean architecture, PostHog is integrated as a **library** matching the existing logging infrastructure pattern:

```
lib/libraries/analytics/
├── domain/
│   ├── entities/
│   │   ├── analytics_event.dart
│   │   └── analytics_user_properties.dart
│   ├── repositories/
│   │   ├── analytics_repository.dart      # Abstract contract
│   │   └── feature_flag_repository.dart   # Abstract contract (separate per SRP; Phase 4 — not created in Phase 1 Foundation)
│   └── types/
│       └── analytics_error_type.dart
├── data/
│   ├── repositories/
│   │   ├── analytics_repository_impl.dart
│   │   └── no_op_analytics_repository.dart
│   └── mappers/
│       └── analytics_event_mapper.dart
├── interfaces/
│   ├── posthog_wrapper.dart    # High-level ops consumed by AnalyticsRepositoryImpl
│   └── posthog_sdk.dart        # Thin boundary over the raw posthog_flutter API
├── posthog_wrapper_impl.dart   # Consumes PosthogSdk; mirrors SentryWrapperImpl
├── posthog_sdk_impl.dart       # Pass-through to Posthog(); mirrors SentrySdkImpl
├── testing/
│   └── fake_posthog_sdk.dart   # Mirrors sentry/testing/fake_sentry_sdk.dart
└── analytics_module.dart

lib/app/
└── app_bootstrap.dart
```

### Why This Approach?

1. **Testability**: Fake at the PostHog wrapper boundary (`FakePosthogWrapper`) — keeps real mapping and repository logic under test; the thinner `PosthogSdk` boundary below it is separately faked (`FakePosthogSdk`) to test `PosthogWrapperImpl` itself
2. **Flexibility**: Swap PostHog for another provider without touching business logic
3. **Consistency**: Matches existing patterns (logging, Supabase wrapper, router)
4. **Separation of Concerns**: Domain layer never imports PostHog directly
5. **Type Safety**: Strongly-typed events and properties

---

## Installation & Setup

### Step 1: Add Dependencies

```yaml
dependencies:
  posthog_flutter: ^5.35.1  # Verified against pub.dev 2026-08-06 — re-check before implementation

  # Optional: session replay (adds ~2MB to app size)
  # posthog_flutter:
  #   version: ^5.35.1
  #   features: [session-replay]
```

```bash
fvm flutter pub get
```

### Step 2: Platform-Specific Configuration

**Android** (`android/app/build.gradle`):
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // PostHog Flutter SDK requires API 21+
    }
}
```

**iOS** (`ios/Podfile`):
```ruby
platform :ios, '13.0'  # PostHog Flutter SDK requires iOS 13+
```

```bash
cd ios && pod install && cd ..
```

### Step 3: Environment Configuration

`assets/env/.env.dev`, `.env.qa`, `.env.prod` are **CI-generated** by
`scripts/ci/generate_env_file.sh`, not hand-edited. Add the new keys there — a default
line plus a heredoc entry, mirroring the existing `SENTRY_DSN` pattern — and add
`POSTHOG_API_KEY`/`POSTHOG_HOST` (real secrets) to the `construculator_dev` Codemagic
environment group. Add corresponding constants (`posthogApiKeyKey`, `posthogHostKey`,
etc.) to `lib/libraries/config/env_constants.dart`, mirroring `sentryDsnKey`.

```env
POSTHOG_API_KEY=phc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
POSTHOG_HOST=https://us.i.posthog.com
POSTHOG_DEBUG=true  # false in production
```

**No `POSTHOG_ENABLED` flag.** Reuse the existing `ANALYTICS_ENABLED` flag (already
written by `generate_env_file.sh`, zero consumers today) as the analytics kill switch —
introducing a second enable flag would be a foot-gun for the rollback plan, which
depends on there being exactly one. *Decided: Ayana, 2026-08-06 (CA-939).*

**Host is fixed at `https://us.i.posthog.com`** — Cloud, US region. *Decided: Suyang,
2026-08-05.* EU residency is out of scope; revisit only if EU users become a target
(a migration + compliance workstream, not a config change).

**Project creation is phased**, not "one project per environment from day one": only
the **dev** Cloud project is created now (CA-943); qa and prod projects are deferred
until those flavors actually need analytics capture, matching Phase 6 below.
*Decided: Ayana, 2026-08-06.*

### Step 4: Create Analytics Library Structure

Create the folder structure as defined in [Architecture Integration](#architecture-integration).

### Step 5: Consent, Privacy, and Initialization Order (Required)

1. App starts with analytics capture disabled.
2. Show privacy/consent prompt (if required by region/product policy).
3. If consent granted: initialize analytics.
4. Only identify user after authentication **and** consent.
5. If consent revoked: call `reset()`, stop tracking, persist opt-out.

**Consent decision:** the existing signup terms & privacy acceptance covers product
analytics — there is no separate opt-in flow. *Decided: Suyang, 2026-08-05.* Caveat:
the T&P text itself is still being finalized, so the enable/consent check must stay
cheap to flip. To keep it that way, the check lives at a **single point in
`PosthogWrapper`**, never at individual call sites — if the T&P work later requires
opt-in, that's one gate to wire rather than every instrumentation call to retrofit.

**Hard rule:** Do not send raw route arguments, free text, or sensitive values in event properties.

---

## Clean Architecture Implementation

### Domain Layer: Analytics Repository Interface

**File:** `lib/libraries/analytics/domain/repositories/analytics_repository.dart`

```dart
/// Domain-only contract. SDK lifecycle methods (initialize, flush) are
/// infrastructure concerns handled in AnalyticsRepositoryImpl and app bootstrap.
abstract class AnalyticsRepository {
  Future<Either<Failure, void>> track(AnalyticsEvent event);

  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  });

  Future<Either<Failure, void>> reset();

  Future<Either<Failure, void>> setUserProperties(AnalyticsUserProperties properties);

  Future<Either<Failure, void>> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? properties,
  });
}
```

### Domain Layer: Feature Flag Repository Interface

> **Phase 4 scope.** `FeatureFlagRepository` is not part of the Phase 1 Foundation — it
> lands with Feature Flags work (see [Migration & Rollout Plan](#migration--rollout-plan)).
> Do not create this file alongside `AnalyticsRepository` in Phase 1.

**File:** `lib/libraries/analytics/domain/repositories/feature_flag_repository.dart`

```dart
/// Separated from AnalyticsRepository to follow Single Responsibility Principle.
abstract class FeatureFlagRepository {
  Future<Either<Failure, bool?>> isFeatureEnabled(String featureFlagKey);
  Future<Either<Failure, String?>> getFeatureFlagVariant(String featureFlagKey);
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(String featureFlagKey);
  Future<Either<Failure, void>> reloadFeatureFlags();
}
```

### Domain Layer: Entities

```dart
// analytics_event.dart
class AnalyticsEvent {
  const AnalyticsEvent({required this.name, this.properties = const {}});
  final String name;
  final Map<String, dynamic> properties;
}

// analytics_user_properties.dart
class AnalyticsUserProperties {
  const AnalyticsUserProperties({this.email, this.name, this.role, this.custom = const {}});
  final String? email;
  final String? name;
  final String? role;
  final Map<String, dynamic> custom;

  Map<String, dynamic> toMap() => {
    if (email != null) 'email': email,
    if (name != null) 'name': name,
    if (role != null) 'role': role,
    ...custom,
  };
}
```

### Data Layer: PostHog SDK Boundary

Mirrors the existing `SentrySdk`/`SentryWrapper` split
(`lib/libraries/sentry/interfaces/sentry_sdk.dart` + `sentry_wrapper.dart`,
`sentry_wrapper_impl.dart`): `PosthogSdk` is a thin, untestable pass-through to the
`posthog_flutter` `Posthog()` singleton (native platform channels, same rationale as
`SentrySdkImpl`'s `// coverage:ignore-file`); `PosthogWrapper` is the high-level,
fakeable boundary `AnalyticsRepositoryImpl` depends on. `PosthogWrapperImpl`
constructor-injects a `PosthogSdk` and delegates every call to it — exactly like
`SentryWrapperImpl` delegates to `SentrySdk`.

**File:** `lib/libraries/analytics/interfaces/posthog_sdk.dart`

```dart
/// Thin boundary over the raw posthog_flutter API. Exists so
/// PosthogWrapperImpl's own logic (consent gating, mapping) can be
/// unit-tested against a fake; the real implementation is a pass-through
/// to native platform channels and therefore untestable (mirrors SentrySdk).
abstract class PosthogSdk {
  Future<void> setup(PostHogConfig config);
  Future<void> capture({required String eventName, Map<String, Object>? properties});
  Future<void> identify({required String userId, Map<String, Object>? userProperties});
  // reset(), setUserProperties(), group() delegate the same way — omitted for brevity
}
```

**File:** `lib/libraries/analytics/posthog_sdk_impl.dart`

```dart
// coverage:ignore-file
// Thin pass-through to the Posthog() singleton, which relies on native
// platform channels and therefore cannot be exercised in unit tests.
class PosthogSdkImpl implements PosthogSdk {
  final _posthog = Posthog();

  @override
  Future<void> setup(PostHogConfig config) => _posthog.setup(config);

  @override
  Future<void> capture({required String eventName, Map<String, Object>? properties}) =>
      _posthog.capture(eventName: eventName, properties: properties);

  @override
  Future<void> identify({required String userId, Map<String, Object>? userProperties}) =>
      _posthog.identify(userId: userId, userProperties: userProperties);
}
```

**File:** `lib/libraries/analytics/posthog_wrapper_impl.dart`

```dart
class PosthogWrapperImpl implements PosthogWrapper {
  PosthogWrapperImpl({required PosthogSdk posthogSdk}) : _posthogSdk = posthogSdk;
  final PosthogSdk _posthogSdk;

  @override
  Future<void> setup(PostHogConfig config) => _posthogSdk.setup(config);

  @override
  Future<void> capture({required String eventName, Map<String, Object>? properties}) =>
      _posthogSdk.capture(eventName: eventName, properties: properties);

  @override
  Future<void> identify({required String userId, Map<String, Object>? userProperties}) =>
      _posthogSdk.identify(userId: userId, userProperties: userProperties);
  // reset(), setUserProperties(), group() follow the same delegation pattern
}
```

`PosthogWrapperImpl`'s own tests inject a `FakePosthogSdk`
(`lib/libraries/analytics/testing/fake_posthog_sdk.dart`, mirroring
`sentry/testing/fake_sentry_sdk.dart`) rather than the real platform channel —
separate from `FakePosthogWrapper` below, which fakes one layer up so
`AnalyticsRepositoryImpl`'s own mapping logic stays under test.

### Data Layer: PostHog Repository Implementation

```dart
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl({
    required String apiKey,
    required String host,
    required PosthogWrapper posthogWrapper,
  })  : _apiKey = apiKey,
        _host = host,
        _posthog = posthogWrapper;

  Future<Either<Failure, void>> initialize() async {
    final config = PostHogConfig(_apiKey)
      ..host = _host
      ..personProfiles = PostHogPersonProfiles.identifiedOnly;
    await _posthog.setup(config);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> track(AnalyticsEvent event) async {
    await _posthog.capture(eventName: event.name, properties: event.properties);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  }) async {
    await _posthog.identify(userId: userId, userProperties: properties.toMap());
    return const Right(null);
  }
  // reset(), setUserProperties(), group() follow the same pattern
}
```

### Data Layer: No-Op Repository

```dart
/// Production no-op used when ANALYTICS_ENABLED=false.
/// Not a test double — for tests, inject FakePosthogWrapper into AnalyticsRepositoryImpl.
class NoOpAnalyticsRepository implements AnalyticsRepository {
  @override Future<Either<Failure, void>> track(AnalyticsEvent event) async => const Right(null);
  @override Future<Either<Failure, void>> identify({required String userId, required AnalyticsUserProperties properties}) async => const Right(null);
  @override Future<Either<Failure, void>> reset() async => const Right(null);
  @override Future<Either<Failure, void>> setUserProperties(AnalyticsUserProperties properties) async => const Right(null);
  @override Future<Either<Failure, void>> group({required String groupType, required String groupKey, Map<String, dynamic>? properties}) async => const Right(null);
}
```

### Module Configuration & App Bootstrap

SDK initialization is an infrastructure concern and must happen **before** Modular
loads — `AppBootstrap` exists precisely for this. Following the same pattern as
`SupabaseWrapperImpl`/`SentryWrapperImpl`/`AppConfigImpl`: construct the repository in
`_initializeApp()` in `main.dart` using the already-threaded `EnvLoader` (never
`dotenv.env[...]` directly), await its `initialize()`, and add the result as a field on
`AppBootstrap`. The module then only *exposes* the pre-built instance — it never
constructs it and never calls `Modular.get` outside a module file
(`forbid_modular_get_outside_module`, CA-626/CA-627).

```dart
// lib/main.dart — inside _initializeApp(), after envLoader/config/supabaseWrapper/sentryWrapper:
final enabled = envLoader.get(analyticsEnabledKey) == 'true';
final analyticsRepository = enabled
    ? AnalyticsRepositoryImpl(
        apiKey: envLoader.get(posthogApiKeyKey) ?? '',
        host: envLoader.get(posthogHostKey) ?? '',
        posthogWrapper: PosthogWrapperImpl(posthogSdk: PosthogSdkImpl()),
      )
    : NoOpAnalyticsRepository();
if (analyticsRepository is AnalyticsRepositoryImpl) {
  await analyticsRepository.initialize();
}
return AppBootstrap(
  // ...existing fields...
  analyticsRepository: analyticsRepository,
);
```

```dart
// lib/libraries/analytics/analytics_module.dart — mirrors ConfigModule
class AnalyticsModule extends Module {
  final AppBootstrap appBootstrap;
  AnalyticsModule(this.appBootstrap);

  @override
  void exportedBinds(Injector i) {
    i.addSingleton<AnalyticsRepository>(() => appBootstrap.analyticsRepository);
  }
}
```

---

## Event Tracking Strategy

> The full event taxonomy is maintained in [PostHog Event Tracking](PostHog-Event-Tracking.md).

### Tracking Implementation Examples

**Track Events in BLoC:**

```dart
class AddCostEstimationBloc {
  final AnalyticsRepository _analyticsRepository;

  Future<void> _onCreateEstimation() async {
    final result = await _useCase(...);
    result.fold(
      (failure) => emit(error),
      (estimation) {
        _analyticsRepository.track(AnalyticsEvent(
          name: 'estimation_created',
          properties: {'estimation_id': estimation.id, 'project_id': estimation.projectId},
        ));
        emit(success);
      },
    );
  }
}
```

**Identify Users on Login:**

```dart
await _analyticsRepository.identify(
  userId: userProfile.id,
  properties: AnalyticsUserProperties(email: userProfile.email, role: userProfile.role),
);
await _analyticsRepository.track(AnalyticsEvent(name: 'user_logged_in'));
```

**Track Screen Views in Router:**

> **Not a drop-in `PosthogObserver()`.** The app uses `MaterialApp.router` with
> `Modular.routerConfig`, not the legacy Navigator API — Sentry's equivalent observer is
> wired via `Modular.routerDelegate.setObservers([SentryNavigatorObserver()])` in
> `lib/app/app.dart`. If screen-view tracking moves to an observer-based approach
> (CA-944) instead of the manual `track()` call below, it must go through
> `Modular.routerDelegate.setObservers([...])` the same way.

```dart
class AppRouterImpl {
  void navigate(String route) {
    _analyticsRepository.track(AnalyticsEvent(
      name: 'screen_viewed',
      properties: {'screen_name': route},
    ));
    Modular.to.pushNamed(route);
  }
}
```

---

## Funnels & Analytics

All funnels below are sample templates. Final events, steps, and conversion windows must be updated based on the implemented UX.

### Critical Funnels

#### 1. User Onboarding Funnel

**Steps:** `user_registered` → `user_logged_in` → `project_created` → `estimation_created` → `estimation_viewed`

**PostHog Setup:** Product Analytics → Funnels → New Funnel
- Conversion window: **7 days**
- Breakdown by: `signup_method`, `platform`

#### 2. Upload Documents Funnel (EST-023)

**Requirement:** EST-023 — Cost Details > Upload Documents (category selection required before upload)

**Steps:**
1. `upload_category_bottom_sheet_viewed`
2. `upload_category_selected` (`drawing`, `rfi`, `receipts`, `other`)
3. `document_upload_started`
4. `document_uploaded`

**Properties:** `estimation_id`, `project_id`, `document_category`, `file_type`, `file_size_bytes`, `upload_duration_ms`, `source_screen`

**PostHog Setup:** Conversion window: **30 minutes** · Breakdown by: `document_category`, `file_type`, `platform`

**Validation rule:** Track `document_upload_validation_failed` with `validation_error = category_required` on premature upload attempt.

#### 3. Project Switching Funnel (Future)

**Steps:** `project_viewed` → `project_dropdown_clicked` → `search_performed` → `project_switched` → `estimation_viewed`

**PostHog Setup:** Conversion window: **10 minutes** · Filter: users with 2+ projects

---

### AARRR Metrics (Pirate Funnel)

| Stage | Key Events | Metrics |
|-------|-----------|---------|
| **Acquisition** | `user_registered` | Signups per day/week, acquisition channel |
| **Activation** | `estimation_created` (within 7 days) | % who create first estimation |
| **Retention** | `user_logged_in` (weekly) | Weekly active users, retention cohorts |
| **Referral** | `user_invited`, `invite_accepted` | Referral rate, viral coefficient |
| **Revenue** | `subscription_started`, `plan_upgraded` | MRR growth, ARPU, plan conversion rate |

### Setting Up Retention Cohorts

1. Product Analytics → Insights → New Insight → **Retention**
2. Cohort defining event: `user_registered` · Return event: `user_logged_in` · By: Week
3. Time range: Last 12 weeks
4. Save as: `User Retention by Signup Week` and add to Executive Dashboard

**Benchmarks:** Week 4 retention > 20% is healthy. Week 1 retention < 20% signals an onboarding problem.

---

## Feature Flags

Feature flags enable gradual rollouts, A/B testing, and remote configuration without shipping an app update.

### Use Cases for Construculator

#### 1. Gradual Rollout: Global Search

**Flag key:** `global_search_enabled` (Boolean)

```dart
return BlocBuilder<FeatureFlagBloc, FeatureFlagState>(
  buildWhen: (prev, curr) => prev.globalSearchEnabled != curr.globalSearchEnabled,
  builder: (context, state) {
    if (!state.globalSearchEnabled) return const SizedBox.shrink();
    return IconButton(icon: const Icon(Icons.search), onPressed: () => _openGlobalSearch(context));
  },
);
```

**Rollout schedule:** Week 1: 10% → Week 2: 25% (if error rate < 1%) → Week 3: 50% → Week 4: 100%

**Rollback:** Set rollout to 0% in PostHog — takes effect immediately, no app update needed.

#### 2. Other Flag Patterns

```dart
// Plan-gated feature
final canAttach = await _featureFlagRepo.isFeatureEnabled('file_attachments_enabled');

// Multivariate config
final variant = await _featureFlagRepo.getFeatureFlagVariant('estimation_page_size');
final pageSize = switch (variant) { 'variant_30' => 30, 'variant_50' => 50, _ => 20 };

// JSON payload (remote config)
final payload = await _featureFlagRepo.getFeatureFlagPayload('estimation_templates_config');
```

### Monitoring Flag Usage

**View Flag Exposure:** Feature Flags → select flag → Insights tab

**Compare Flag Impact:**
1. Insights → New Insight → Trends
2. Event: goal metric (e.g., `estimation_created`)
3. Add Breakdown → Feature Flag: `global_search_enabled`
4. Compare ON vs OFF conversion rates

### Feature Flag Best Practices

1. Always handle `null` return values gracefully — treat `null` as feature off
2. Cache flag values in BLoC state — never evaluate flags inside `build()`
3. Archive flags promptly once fully rolled out
4. Register every active flag in the [Feature Flag Registry](#posthog-feature-flag-registry)

---

## A/B Testing & Experiments

> **Terminology note:** PostHog's product term is "Experiment" — a structured, statistically-tracked study. Not a loose comparison of two configurations. See the [Terminology](#terminology) section for full definitions.

### When to Use A/B Tests vs Feature Flags

| Use Case | Tool |
|----------|------|
| Gradual rollout (same UX) | Feature Flag |
| Test two different UIs | A/B Test (Experiment) |
| Remote config | Feature Flag (JSON payload) |
| Measure conversion impact | A/B Test (Experiment) |

### A/B Test Example: Estimation Creation Flow

**Hypothesis:** A guided wizard increases estimation completion rate vs. a single-step dialog.

**PostHog Setup:** Experiments → New Experiment
- Flag key: `estimation_creation_flow`
- Variants: `control` (50%) — single-step dialog / `wizard` (50%) — multi-step wizard
- Goal: `estimation_created` with +5% target lift

```dart
final variant = await _featureFlagRepo.getFeatureFlagVariant('estimation_creation_flow');
if (variant == 'wizard') {
  _showWizardDialog();
} else {
  _showSingleStepDialog();
}
await _analyticsRepo.track(AnalyticsEvent(name: 'estimation_created', properties: {...}));
```

**Monitor:** Experiments → select experiment → wait for statistical significance → Ship winning variant.

### Experiment Best Practices

1. Run one experiment per feature area to avoid interaction effects
2. Never call results early — wait for statistical significance
3. Track secondary metrics to catch negative side effects

---

## Group Analytics (B2B)

> **Billing:** Group Analytics is a paid PostHog add-on — not included in the free tier. Confirm plan eligibility before enabling.

Group analytics enables **account-level** behavioral analysis (projects, companies) alongside individual user data.

### Use Cases

1. Which projects have the most estimations? Which are dormant?
2. Company-level usage across all users (future)
3. Account health scoring: identify at-risk projects

### Implementation

```dart
// Call once per group type when user selects a project
await _analyticsRepository.group(
  groupType: 'project',
  groupKey: project.id,
  properties: {'project_name': project.name, 'project_status': project.status},
);

// Simultaneously associate with company (separate call required)
await _analyticsRepository.group(
  groupType: 'company',
  groupKey: user.companyId,
  properties: {'company_tier': user.companyTier},
);
```

All subsequent events are automatically tagged with all active group IDs.

> **Multi-group limitation:** The current `group()` interface accepts one type per call — callers must invoke it once per group type or miss an association. A `setGroups(List<AnalyticsGroup>)` batch overload should be added before production use. Tracked as [TODO CA-700](https://ripplearc.youtrack.cloud/issue/CA-700).

### PostHog Dashboard Setup

1. Settings → Project Settings → Group Analytics → Add Group Type: `project`
2. Create insights with breakdown by **Group: project** to see most active/dormant projects

---

## Dashboard Configuration

### Key Dashboards

#### 1. Executive Dashboard (`Executive Overview`)

| Widget | Insight Type | Event | Config |
|--------|-------------|-------|--------|
| Active Users | Trends | Any event | Unique users, last 30 days |
| New Signups | Trends | `user_registered` | Total count, by week |
| Estimations Created | Trends | `estimation_created` | Total count, by week |
| Onboarding Funnel | Funnel | — | Link to User Onboarding Funnel |

#### 2. Product Health Dashboard (`Product Health`)

**Upload Success Rate:** `A / B * 100` where A = `document_uploaded`, B = `document_upload_started`

**Error Rate by Type:** `error_occurred` · breakdown by `error_type` · stacked bar

**Top Events:** All events · breakdown by event name · bar chart (top 10)

#### 3. Feature Flags Dashboard (`Feature Flags & Experiments`)

Pin active experiments + flag exposure widget: event `$feature_flag_called` · breakdown by `feature_flag`

### Dashboard-to-Event Matrix

| Widget | Event | Required Properties |
|--------|-------|---------------------|
| Active Users | Any event | — |
| New Signups | `user_registered` | — |
| Estimations Created | `estimation_created` | `project_id` |
| Upload Success Rate | `document_uploaded`, `document_upload_started` | `document_category`, `file_type` |
| Error Rates | `error_occurred` | `error_type`, `screen_name` |
| Flag Exposure | `$feature_flag_called` | `feature_flag` (auto-added by SDK) |

### Setting Up Alerts

- **Error Rate Spike:** `error_occurred` > 100 in 1 hour → Email + Slack
- **DAU Drop:** Unique users drops > 20% vs previous day → Email to leadership
- **Experiment Complete:** Enable "Notify when statistically significant" on active experiments

---

## Testing Strategy

### Unit Testing

Fake at the PostHog SDK wrapper boundary — not at `AnalyticsRepository` — so mapping logic stays under test:

```dart
class FakePosthogWrapper implements PosthogWrapper {
  final List<String> capturedEvents = [];

  @override
  Future<void> capture({required String eventName, Map<String, Object?>? properties}) async {
    capturedEvents.add(eventName);
  }

  @override
  Future<void> identify({required String userId, Map<String, Object?>? userProperties}) async {}
}

test('tracks estimation_created via AnalyticsRepositoryImpl', () async {
  final fakePosthog = FakePosthogWrapper();
  final repo = AnalyticsRepositoryImpl(posthogWrapper: fakePosthog);
  await repo.track(AnalyticsEvent(name: 'estimation_created'));
  expect(fakePosthog.capturedEvents, contains('estimation_created'));
});
```

### BLoC Testing

When analytics is a side effect (not the test subject), inject `NoOpAnalyticsRepository`:

```dart
blocTest<AddCostEstimationBloc, AddCostEstimationState>(
  'emits success after estimation creation',
  build: () => AddCostEstimationBloc(
    addCostEstimationUseCase: FakeAddCostEstimationUseCase(),
    analyticsRepository: NoOpAnalyticsRepository(),
  ),
  act: (bloc) => bloc.add(CreateEstimation(...)),
  expect: () => [loading, success],
);
```

### Manual Testing

1. Set `POSTHOG_DEBUG=true` in `.env.dev`
2. Trigger events in the app
3. Verify in PostHog under **Activity → Live Events**
4. Test flag overrides using email conditions in PostHog dashboard

---

## Migration & Rollout Plan

> The phases below show sequencing and dependencies, not a committed schedule. Set actual timelines during sprint planning.

### Phase 1: Foundation
- [ ] Add `posthog_flutter` dependency
- [ ] Create analytics library structure (domain + data layers)
- [ ] Add environment configuration
- [ ] Initialize analytics in `app_bootstrap.dart`
- [ ] Track a test event and verify it in PostHog dev dashboard

### Phase 2: Core Events
- [ ] Add analytics to authentication BLoCs
- [ ] Track user identification on login
- [ ] Track estimation CRUD events
- [ ] Track project selection and switching
- [ ] Implement screen view tracking in router
- [ ] Create User Onboarding funnel

### Phase 3: Advanced Analytics
- [ ] Enrich events with full property sets
- [ ] Create retention cohorts dashboard
- [ ] Set up critical metric alerts

### Phase 4: Feature Flags
- [ ] Create first flag (`global_search_enabled`)
- [ ] Implement via `FeatureFlagBloc`
- [ ] Validate gradual rollout flow
- [ ] Document in [Feature Flag Registry](#posthog-feature-flag-registry)

### Phase 5: Experiments
- [ ] Design first A/B test (estimation creation flow)
- [ ] Implement control and variant paths
- [ ] Run experiment to statistical significance

### Phase 6: Production Rollout
- [ ] Audit and prune unnecessary events
- [ ] Create production PostHog project with its own API key
- [ ] Enable for 10% of prod users via kill-switch flag, then ramp

**Go/No-Go Checklist:**
- [ ] Error rate < 1%
- [ ] No measurable performance degradation
- [ ] Events correct in production dashboard
- [ ] No PII in event properties
- [ ] GDPR consent enforced before `identify()` / `track()`

### Rollback Plan

1. Set kill-switch flag `analytics_capture_enabled=false` (immediate, no release needed)
2. Call `reset()` for active sessions where required by policy
3. Keep app functional with `NoOpAnalyticsRepository` behavior in code paths
4. For hard-disable: set `ANALYTICS_ENABLED=false` in environment and ship next release

---

## Best Practices

### Event Tracking
1. Use descriptive names: `estimation_created` not `create`
2. Use `snake_case` throughout
3. Include relevant context in properties (IDs, counts, status enums)
4. Never track PII in event properties — use user properties via `identify()` for user-level data
5. Track intent events only when needed for UX funnels; use outcome events for KPI reporting

### Performance
1. PostHog SDK batches events automatically — do not call `flush()` manually
2. Use `await` on tracking calls but do not block critical user paths on analytics completion
3. Cache feature flag values in BLoC state — never evaluate flags inside `build()`

### Privacy & Compliance
1. Set `personProfiles: PostHogPersonProfiles.identifiedOnly`
2. Provide an analytics opt-out in app settings
3. Never track passwords, card data, or government IDs
4. GDPR: enforce consent before `identify()`/`track()`; support deletion requests via PostHog API

### Event Governance
1. Every event must have: owner, description, required properties, allowed enum values
2. Use `event_version` for schema changes that affect existing dashboards
3. Deprecate events with a sunset date before removing them
4. Do not remove old events from dashboards until replacement events are live and validated

---

## PostHog Feature Flag Registry

| Flag Key | Type | Purpose | Owner | Status | Created | Notes |
|----------|------|---------|-------|--------|---------|-------|
| `global_search_enabled` | Boolean | Gradual rollout of global search | @dev-team | Active | 2026-03-23 | Currently 10% rollout |
| `file_attachments_enabled` | Boolean | Premium plan feature gate | @product | Active | 2026-03-23 | Plan-based access |
| `estimation_page_size` | Multivariate | Pagination performance test | @engineering | Testing | 2026-03-23 | Variants: 20/30/50 |
| `estimation_templates_config` | JSON Payload | Remote template configuration | @product | Planned | — | Design in progress |

Add a row when creating any new flag. Archive rows after one sprint once a flag is decommissioned.

---

## Appendix

### PostHog Resources

- [Official Docs](https://posthog.com/docs)
- [Flutter SDK](https://posthog.com/docs/libraries/flutter)
- [Feature Flags](https://posthog.com/docs/feature-flags)
- [Experiments](https://posthog.com/docs/experiments)
- [Group Analytics](https://posthog.com/docs/product-analytics/group-analytics)

### Cost Estimation

> Verify current pricing at [posthog.com/pricing](https://posthog.com/pricing) before capacity planning.

| Scale | MAU | Est. Events/Month | Cost |
|-------|-----|-------------------|------|
| Early | 1,000 | ~30,000 | Free tier |
| Growth | 10,000 | ~300,000 | Free tier |
| Scale | 100,000 | ~3,000,000 | ~$900/mo |

Assumes ~30 events per user per month. Free tier: 1M events/month with unlimited feature flags.
