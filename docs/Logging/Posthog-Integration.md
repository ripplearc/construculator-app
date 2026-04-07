# PostHog Integration Guide for Construculator App

## Table of Contents

1. [Overview](#overview)
2. [Architecture Integration](#architecture-integration)
3. [Installation & Setup](#installation--setup)
4. [Clean Architecture Implementation](#clean-architecture-implementation)
5. [Event Tracking Strategy](#event-tracking-strategy)
6. [Funnels & Analytics](#funnels--analytics)
7. [Feature Flags](#feature-flags)
8. [A/B Testing & Experiments](#ab-testing--experiments)
9. [Group Analytics (B2B)](#group-analytics-b2b)
10. [Dashboard Configuration](#dashboard-configuration)
11. [Testing Strategy](#testing-strategy)
12. [Migration & Rollout Plan](#migration--rollout-plan)
13. [Best Practices](#best-practices)

---

## Overview

### What is PostHog?

PostHog is an all-in-one product analytics platform that provides:
- **Product Analytics**: Event tracking, user behavior analysis, funnels, retention
- **Feature Flags**: Remote configuration and gradual rollouts
- **A/B Testing**: Experimentation with statistical significance
- **Session Replay**: Visual debugging and user journey analysis
- **Group Analytics**: B2B company-level tracking
- **Surveys**: In-app user feedback collection

### Why PostHog for Construculator?

1. **All-in-one**: Consolidates analytics, feature flags, and experiments
2. **Developer-friendly**: Excellent Flutter SDK with clean API
3. **B2B Focus**: Group analytics for tracking organizations/projects
4. **Privacy-first**: GDPR compliant, supports anonymization
5. **Cost-effective**: Generous free tier, predictable pricing

---

## Architecture Integration

### Integration Principles

Following Construculator's clean architecture, PostHog will be integrated as a **library** similar to the existing logging infrastructure:

```
lib/libraries/analytics/
├── domain/
│   ├── entities/
│   │   ├── analytics_event.dart          # Event entity
│   │   └── analytics_user_properties.dart # User properties entity
│   ├── repositories/
│   │   └── analytics_repository.dart      # Abstract contract
│   └── types/
│       └── analytics_error_type.dart      # Error types
├── data/
│   ├── repositories/
│   │   ├── analytics_repository_impl.dart # PostHog implementation
│   │   └── no_op_analytics_repository.dart # Testing/disabled state
│   └── mappers/
│       └── analytics_event_mapper.dart    # Entity to PostHog event
├── interfaces/
│   └── analytics_service.dart             # Service interface
└── analytics_module.dart                   # Module configuration

lib/app/
└── app_bootstrap.dart                      # Initialize analytics on app start
```

### Why This Approach?

1. **Testability**: Isolate analytics in tests using `FakeAnalyticsRepository`
2. **Flexibility**: Swap PostHog for another provider without changing business logic
3. **Consistency**: Matches existing patterns (logging, Supabase wrapper, router)
4. **Separation of Concerns**: Domain layer never depends on PostHog directly
5. **Type Safety**: Strongly-typed events and properties

---

## Installation & Setup

### Step 1: Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  posthog_flutter: ^5.21.0  # Latest version

  # Optional: for session replay (adds ~2MB to app size)
  # posthog_flutter:
  #   version: ^5.21.0
  #   features: [session-replay]
```

Run:
```bash
fvm flutter pub get
```

### Step 2: Platform-Specific Configuration

#### Android (`android/app/build.gradle`)

Update minimum SDK version:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // PostHog requires API 21+
    }
}
```

#### iOS (`ios/Podfile`)

Update minimum iOS version:

```ruby
platform :ios, '13.0'  # PostHog requires iOS 13+
```

Run:
```bash
cd ios && pod install && cd ..
```

### Step 3: Environment Configuration

Add to `assets/env/.env.dev`, `.env.qa`, `.env.prod`:

```env
# PostHog Configuration
POSTHOG_API_KEY=phc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
POSTHOG_HOST=https://us.i.posthog.com  # or https://eu.i.posthog.com for EU
POSTHOG_ENABLED=true
POSTHOG_DEBUG=true  # false in production
```

**Note**: Use different API keys per environment (dev/qa/prod projects in PostHog)

### Step 4: Create Analytics Library Structure

Create the folder structure as defined in [Architecture Integration](#architecture-integration).

### Step 5: Consent, Privacy, and Initialization Order (Required)

Use this sequence to stay GDPR-compliant and avoid capturing data before consent:

1. App starts with analytics capture disabled.
2. Show privacy/consent prompt (if required by region/product policy).
3. If consent is granted: initialize analytics.
4. Only identify user after authentication and consent.
5. If consent is revoked: call `reset()`, stop further tracking, and persist opt-out.

**Important**:
- Do not call `identify()` before consent.
- Do not send raw route arguments, free text, or sensitive values in event properties.
- Treat funnels and event payloads in this document as samples that must be adapted to real implementation details.

---

## Clean Architecture Implementation

### Domain Layer: Analytics Repository Interface

**File:** `lib/libraries/analytics/domain/repositories/analytics_repository.dart`

```dart
/// Abstract repository for analytics operations.
///
/// Implementations should handle all analytics provider-specific logic.
/// Domain layer should only depend on this interface.
abstract class AnalyticsRepository {
  /// Initialize analytics SDK with configuration.
  ///
  /// Should be called once during app bootstrap.
  Future<Either<Failure, void>> initialize();

  /// Track a custom event with optional properties.
  ///
  /// Events are queued and sent in batches for performance.
  Future<Either<Failure, void>> track(AnalyticsEvent event);

  /// Identify the current user and set user properties.
  ///
  /// Call this after successful authentication.
  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  });

  /// Reset user identity (on logout).
  ///
  /// Clears user properties and generates new anonymous ID.
  Future<Either<Failure, void>> reset();

  /// Set or update user properties without identifying.
  Future<Either<Failure, void>> setUserProperties(
    AnalyticsUserProperties properties,
  );

  /// Set group properties (for B2B analytics).
  ///
  /// Groups typically represent companies, organizations, or projects.
  Future<Either<Failure, void>> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? properties,
  });

  /// Flush all pending events immediately.
  ///
  /// Useful before app termination or background.
  Future<Either<Failure, void>> flush();
}
```

### Domain Layer: Feature Flag Repository Interface

**File:** `lib/libraries/analytics/domain/repositories/feature_flag_repository.dart`

```dart
/// Abstract repository for feature flag operations.
///
/// Separated from AnalyticsRepository to follow Single Responsibility Principle.
abstract class FeatureFlagRepository {
  /// Get feature flag value by key.
  Future<Either<Failure, bool?>> isFeatureEnabled(String featureFlagKey);

  /// Get feature flag variant (for multivariate flags).
  Future<Either<Failure, String?>> getFeatureFlagVariant(String featureFlagKey);

  /// Get feature flag payload (JSON data attached to flag).
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(
    String featureFlagKey,
  );

  /// Reload feature flags from server.
  Future<Either<Failure, void>> reloadFeatureFlags();
}
```

### Domain Layer: Entities

**File:** `lib/libraries/analytics/domain/entities/analytics_event.dart`

```dart
class AnalyticsEvent {
  const AnalyticsEvent({required this.name, this.properties = const {}});
  final String name;
  final Map<String, dynamic> properties;
}
```

**File:** `lib/libraries/analytics/domain/entities/analytics_user_properties.dart`

```dart
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

### Data Layer: PostHog Repository Implementation

**File:** `lib/libraries/analytics/data/repositories/analytics_repository_impl.dart`

```dart
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  // Initialize PostHog SDK
  Future<Either<Failure, void>> initialize() async {
    final config = PostHogConfig(_apiKey)
      ..host = _host
      ..personProfiles = PostHogPersonProfiles.identifiedOnly;
    await Posthog().setup(config);
    return const Right(null);
  }

  // Track events via Posthog().capture()
  Future<Either<Failure, void>> track(AnalyticsEvent event) async {
    await Posthog().capture(eventName: event.name, properties: event.properties);
    return const Right(null);
  }

  // Identify users via Posthog().identify()
  Future<Either<Failure, void>> identify({required String userId, required AnalyticsUserProperties properties}) async {
    await Posthog().identify(userId: userId, userProperties: properties.toMap());
    return const Right(null);
  }

  // Other methods: reset(), setUserProperties(), group(), flush()
}
```

### Data Layer: Fake Repository (for Testing)

**File:** `lib/libraries/analytics/data/repositories/no_op_analytics_repository.dart`

```dart
/// Fake implementation for testing or when analytics is disabled.
class FakeAnalyticsRepository implements AnalyticsRepository {
  // All methods return Right(null) - no actual tracking occurs
  Future<Either<Failure, void>> initialize() async => const Right(null);
  Future<Either<Failure, void>> track(AnalyticsEvent event) async => const Right(null);
  // ... other methods
}
```

### Module Configuration & App Bootstrap

Configure module bindings based on environment:

```dart
class AnalyticsModule extends Module {
  void binds(i) {
    final enabled = dotenv.env['POSTHOG_ENABLED'] == 'true';
    i.addLazySingleton<AnalyticsRepository>(
      enabled ? () => AnalyticsRepositoryImpl(...) : FakeAnalyticsRepository.new
    );
  }
}
```

Initialize in app bootstrap:

```dart
class AppBootstrap {
  static Future<void> initialize() async {
    // Check consent before initializing analytics
    final analyticsRepository = Modular.get<AnalyticsRepository>();
    await analyticsRepository.initialize();
  }
}
```

---

## Event Tracking Strategy

### Event Naming Convention

Follow PostHog best practices with snake_case naming:

**Pattern:** `{object}_{action}` (e.g., `estimation_created`, `project_switched`)

**Event Categories:**

1. **Authentication Events**
   - `user_registered`
   - `user_logged_in`
   - `user_logged_out`
   - `user_password_reset`
   - `otp_verified`

2. **Estimation Events**
   - `estimation_created`
   - `estimation_viewed`
   - `estimation_renamed`
   - `estimation_deleted`
   - `estimation_locked`
   - `estimation_unlocked`
   - `estimation_duplicated`
   - `estimation_exported`

3. **Project Events**
   - `project_created`
   - `project_switched`
   - `project_viewed`
   - `project_archived`
   - `project_restored`
   - `project_deleted`

4. **Search Events** (future)
   - `search_performed`
   - `search_result_clicked`
   - `global_search_used`

5. **File Events** (future)
   - `file_uploaded`
   - `file_downloaded`
   - `file_deleted`
   - `attachment_added`

6. **Collaboration Events**
   - `estimation_shared`
   - `user_invited`
   - `comment_added`

7. **Navigation Events**
   - `screen_viewed`
   - `tab_switched`
   - `navigation_clicked`

8. **Performance & Reliability Events**
  - `screen_loaded`
  - `error_occurred`
  - `api_call_completed`

### Data Safety Rules (Required)

Use allow-listed properties and stable schemas:

| Property Type | Allowed Examples | Forbidden Examples |
|--------------|------------------|--------------------|
| Event properties | IDs, enums, booleans, bounded counters, duration ms | Email, phone, raw search text with PII, full route arguments, tokens |
| User properties | Plan type, role, company tier, account age bucket | Passwords, payment card data, SSN |
| Group properties | Project status, project size bucket | Free-form notes, confidential document names |

Always keep event cardinality bounded (avoid unbounded strings in keys used for breakdowns).

### Event Properties

**Standard Properties** (include in all events):

```dart
{
  'timestamp': DateTime.now().toIso8601String(),
  'app_version': '1.0.0',
  'platform': Platform.isIOS ? 'ios' : 'android',
  'screen_name': '/estimation/details',
}
```

**Context-Specific Properties:**

```dart
// Estimation events
{
  'estimation_id': 'uuid',
  'estimation_name': 'Kitchen Remodel',
  'project_id': 'uuid',
  'total_cost': 15000.50,
  'item_count': 25,
  'is_locked': true,
}

// Project events
{
  'project_id': 'uuid',
  'project_name': 'Residential Complex A',
  'project_status': 'active',
  'estimation_count': 12,
}

// Search events
{
  'query': 'kitchen',
  'results_count': 15,
  'search_type': 'global', // or 'project', 'estimation'
  'time_to_result_ms': 250,
}
```

### Tracking Implementation Examples

#### Track Events in BLoC

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

#### Identify Users on Login

```dart
await _analyticsRepository.identify(
  userId: userProfile.id,
  properties: AnalyticsUserProperties(email: userProfile.email, role: userProfile.role),
);
await _analyticsRepository.track(AnalyticsEvent(name: 'user_logged_in'));
```

#### Track Screen Views in Router

```dart
class AppRouterImpl {
  void navigate(String route) {
    _analyticsRepository.track(AnalyticsEvent(name: 'screen_viewed', properties: {'screen_name': route}));
    Modular.to.pushNamed(route);
  }
}
```

#### Set Group Context (B2B)

```dart
await _analyticsRepository.group(
  groupType: 'project',
  groupKey: project.id,
  properties: {'project_name': project.name, 'project_status': project.status},
);
```

---

## Funnels & Analytics

All funnels in this section are sample templates. Final events, steps, and windows must be updated based on the implemented UX and actual instrumentation details.

### Critical Funnels for Construculator

#### 1. User Onboarding Funnel

**Goal:** Track user activation from signup to first estimation

**Steps:**
1. `user_registered` - User completes registration
2. `user_logged_in` - First successful login
3. `project_created` - User creates first project
4. `estimation_created` - User creates first estimation
5. `estimation_viewed` - User views estimation details

**PostHog Dashboard Setup:**
- Navigate to **Product Analytics** → **Funnels**
- Click **New Funnel**
- Name: "User Onboarding Funnel"
- Add steps in order (as above)
- Conversion window: **7 days** (time allowed between steps)
- Breakdown by: `signup_method`, `platform` (iOS/Android)

**Key Metrics:**
- Overall conversion rate (signup → first estimation)
- Drop-off points (where users leave)
- Time between steps
- Cohort comparison (by signup date, platform)

**Actionable Insights:**
- If drop-off is high between registration and project creation, improve onboarding tutorial
- If users create project but not estimation, add guided creation wizard

#### 2. Upload Documents Funnel (EST-023)

**Requirement ID:** EST-023  
**PRD Section:** Cost Details > Upload Documents Button

**Requirement Summary:**
When users tap Upload Documents from estimation cost details, show a bottom sheet requiring category selection before upload. Categories: `drawing`, `rfi`, `receipts`, `other`.

**Goal:** Measure successful completion of category-required document upload flow.

**Steps:**

1. `upload_category_bottom_sheet_viewed` - Category picker bottom sheet shown
2. `upload_category_selected` - User selects one category (`drawing`, `rfi`, `receipts`, `other`)
3. `document_upload_started` - Upload begins after valid category selection
4. `document_uploaded` - Upload completes successfully

**Recommended Properties:**
- `estimation_id`
- `project_id`
- `document_category`
- `file_type`
- `file_size_bytes`
- `upload_duration_ms`
- `source_screen` (for example: `cost_details`)

**PostHog Dashboard Setup:**
- Conversion window: **30 minutes**
- Breakdown by: `document_category`, `file_type`, `platform`
- Optional filter: `source_screen = cost_details`

**Key Metrics:**
- Upload completion rate
- Category selection-to-upload drop-off
- Upload failure rate by file type/category

**Validation Rule to Track Explicitly:**
- If user attempts upload without selecting category, track `document_upload_validation_failed` with `validation_error = category_required`.

#### 3. Project Switching Funnel (Future)

**Goal:** Understand multi-project usage

**Steps:**
1. `project_viewed` - View current project
2. `project_dropdown_clicked` - Click project switcher
3. `search_performed` (search_type: 'project') - Search for project
4. `project_switched` - Switch to different project
5. `estimation_viewed` - View estimation in new project

**PostHog Dashboard Setup:**
- Conversion window: **10 minutes**
- Breakdown by: `user_id`, `project_count`
- Filter: Users with 2+ projects


### AARRR Metrics (Pirate Funnel)

| Stage | Key Events | Metrics |
|-------|-----------|---------|
| **Acquisition** | `user_registered` | Signups per day/week, Acquisition channel |
| **Activation** | `estimation_created` (within 7 days) | % who create first estimation |
| **Retention** | `user_logged_in` (weekly) | Weekly Active Users, Retention cohorts |
| **Referral** | `user_invited`, `invite_accepted` | Referral rate, Viral coefficient |

### Setting Up Retention Cohorts in PostHog

**Purpose:** Track how many users return to the app over time, grouped by signup week.

**PostHog Dashboard Setup:**

1. Go to **Product Analytics** → **Insights** → **New Insight** → **Retention**
2. Configure cohort:
   - **Cohort defining event**: `user_registered` (when user first appears)
   - **Return event**: `user_logged_in` (what counts as "active")
   - **Cohort by**: Week (group users by signup week)
   - **Show**: Percentage
3. Time range: Last 12 weeks
4. Click **Calculate**
5. Save as: "User Retention by Signup Week"
6. Add to Executive Dashboard

**Reading the Retention Table:**
- **Rows**: Each row = users who signed up in that week
- **Columns**: Week 0 (signup week), Week 1, Week 2, etc.
- **Values**: % of users from that cohort who were active in that week

**Example:**
- Row "Week of Jan 1": 100 users signed up
- Week 0: 100% (all just signed up)
- Week 1: 45% (45 users returned)
- Week 2: 30% (30 users still active)

**Good vs. Bad Retention:**
- **Good**: Week 4 retention > 20% (1 in 5 users still active after a month)
- **Concerning**: Week 1 retention < 20% (users not coming back after first week)

---

## Feature Flags

Feature flags enable gradual rollouts, A/B testing, and remote configuration without app updates.

### Use Cases for Construculator

#### 1. Gradual Feature Rollout: Global Search

**Scenario:** Roll out new global search feature to 10% of users, monitor performance, then increase to 100%.

**Flag Configuration:**

**In PostHog Dashboard:**
1. Navigate to **Feature Flags** → **New Feature Flag**
2. Key: `global_search_enabled`
3. Name: "Global Search Feature"
4. Type: **Boolean**
5. Release conditions:
   - **Rollout percentage**: 10% of users
   - **Override for testing**: `email` contains `@yourcompany.com` → `true`
6. Save

**In Code:**

```dart
// In GlobalSearchWidget
class GlobalSearchWidget extends StatelessWidget {
  const GlobalSearchWidget({
    required this.analyticsRepository,
    super.key,
  });

  final AnalyticsRepository analyticsRepository;

  @override
  Widget build(BuildContext context) {
    // Read from cached state (for example, BLoC/Provider) instead of
    // querying feature flags in build().
    final isEnabled = context.select<FeatureFlagsCubit, bool>(
      (cubit) => cubit.state.globalSearchEnabled,
    );

    if (!isEnabled) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => _openGlobalSearch(context),
    );
  }
}
```

**Gradual Rollout Plan:**
- **Week 1**: 10% rollout, monitor error rates
- **Week 2**: 25% rollout if error rate < 1%
- **Week 3**: 50% rollout
- **Week 4**: 100% rollout

**Rollback Strategy:**
- If critical bug detected, set rollout to 0% in PostHog (takes effect immediately)
- No app update required!

#### 2. Other Feature Flag Use Cases

**User Segmentation:** Gate features by plan type
```dart
// Flag: file_attachments_enabled, condition: plan_type = premium
final canAttach = await _featureFlagRepo.isFeatureEnabled('file_attachments_enabled');
```

**Multivariate Flags:** Test different configurations
```dart
// Flag: estimation_page_size with variants (20, 30, 50)
final variant = await _featureFlagRepo.getFeatureFlagVariant('estimation_page_size');
final pageSize = variant == 'variant_30' ? 30 : (variant == 'variant_50' ? 50 : 20);
```

**JSON Payload:** Complex remote config
```dart
// Flag: estimation_templates_config with JSON payload
final payload = await _featureFlagRepo.getFeatureFlagPayload('estimation_templates_config');
final templates = (payload?['templates'] as List).map((t) => Template.fromJson(t)).toList();
```

### Monitoring Feature Flags in PostHog Dashboard

**View Flag Usage:**
1. Go to **Feature Flags** → Select a flag (e.g., `global_search_enabled`)
2. Click **Insights** tab
3. View:
   - **Unique users** exposed to flag
   - **Rollout percentage** over time
   - **Events triggered** by users with flag enabled vs disabled

**Compare Feature Flag Impact:**
1. Go to **Product Analytics** → **Insights** → **New Insight** → **Trends**
2. Event: `estimation_created` (or your goal metric)
3. Click **Add Breakdown** → **Feature Flag: global_search_enabled**
4. This shows conversion rates for users with flag ON vs OFF
5. Save as: "Global Search Impact on Estimations"

### Feature Flag Best Practices

1. **Always provide fallback values**: Handle `null` or error states gracefully
2. **Cache flag values**: Don't check flags on every render (use BLoC or provider)
3. **Track flag exposures**: Log when users see feature variants
4. **Monitor impact**: Create insights comparing metrics between flag ON/OFF users
5. **Clean up old flags**: Archive flags once features are fully rolled out to 100%
6. **Use consistent naming**: `feature_name_enabled` or `feature_name_config`
7. **Document flags**: Keep a registry of active flags and their purpose

---

## A/B Testing & Experiments

### When to Use A/B Tests vs Feature Flags

| Use Case | Tool | Example |
|----------|------|---------|
| Gradual rollout (same UX) | Feature Flag | Enable new API endpoint for 20% users |
| Test two different UIs | A/B Test | Test button color: blue vs green |
| Remote config | Feature Flag | Adjust pagination size |
| Measure conversion impact | A/B Test | Test onboarding flow: wizard vs single-page |

### A/B Test Example: Estimation Creation Flow

**Hypothesis:** A guided wizard will increase estimation completion rate vs. single-step dialog.

**PostHog Dashboard Setup:**

1. Navigate to **Experiments** → **New Experiment**
2. Name: "Estimation Creation Wizard Test"
3. Feature flag key: `estimation_creation_flow`
4. Variants:
   - `control` (50% of users) - Single-step dialog
   - `wizard` (50% of users) - Multi-step wizard
5. Goal metric:
   - Event: `estimation_created`
   - Success criteria: Increase by at least 5%
6. Click **Save & Launch**

**In Code:**

```dart
// Check variant
final variant = await _featureFlagRepo.getFeatureFlagVariant('estimation_creation_flow');
if (variant == 'wizard') {
  _showWizardDialog();
} else {
  _showSingleStepDialog();
}

// Track goal metric
await _analyticsRepo.track(AnalyticsEvent(name: 'estimation_created', properties: {...}));
```

**Monitor Results:**
1. In PostHog, go to **Experiments** → Select your experiment
2. View real-time conversion rates for each variant
3. Wait for statistical significance (PostHog shows this automatically)
4. Once significant, click **Ship winning variant** to roll out to 100%

### Experiment Best Practices

1. Run one experiment per feature area to avoid interaction effects
2. Wait for statistical significance before concluding
3. Track secondary metrics to ensure no negative side effects

---

## Group Analytics (B2B)

Group analytics is critical for B2B SaaS to understand **account-level** behavior (projects, companies) vs individual users.

### Use Cases

1. **Project-level analytics**: Which projects have the most estimations? Which are active vs dormant?
2. **Company-level analytics** (future): Track usage across all users in a company
3. **Team analytics**: How do teams collaborate on estimations?
4. **Account health scoring**: Identify at-risk projects/companies

### Implementation

Set group context when user selects a project:

```dart
await _analyticsRepository.group(
  groupType: 'project',
  groupKey: project.id,
  properties: {'project_name': project.name, 'project_status': project.status},
);
```

All subsequent events are automatically tagged with the group ID.

### PostHog Dashboard Setup

**Step 1: Enable Group Analytics**

1. Navigate to **Settings** → **Project Settings** → **Group Analytics**
2. Click **Add Group Type**
3. Enter group type: `project`
4. Display name: "Project"
5. Click **Save**

**Step 2: Create Project-Level Insights**

**Most Active Projects:**
1. Go to **Product Analytics** → **Insights** → **New Insight** → **Trends**
2. Event: `estimation_created`
3. Click **Add Breakdown** → Select **Group: project**
4. Time range: Last 30 days
5. Chart type: Bar chart
6. Save as: "Most Active Projects"

**Project Health Score:**
1. New Insight → **Trends**
2. Event: Any event
3. Aggregation: Unique users
4. Breakdown: Group: project
5. Filter: Add formula `events_count > 0` in last 7 days
6. Save as: "Active Projects (Last 7 Days)"

**Dormant Projects Alert:**
1. New Insight → **Trends**
2. Event: Any event
3. Breakdown: Group: project
4. Time range: Last 30 days
5. Click **⋯** → **Set up alert**
6. Alert when: No events for a project in 7 days
7. Save alert

---

## Dashboard Configuration

### Setting Up Key Dashboards

#### 1. Executive Dashboard

**Purpose:** High-level metrics for leadership

**PostHog Setup:**
1. Go to **Dashboards** → **New Dashboard**
2. Name: "Executive Overview"
3. Add these insights:

**Widget 1: Active Users**
- Insight type: **Trends**
- Event: Any event
- Aggregation: Unique users
- Time range: Last 30 days
- Save & add to dashboard

**Widget 2: New Signups**
- Insight type: **Trends**
- Event: `user_registered`
- Aggregation: Total count
- Time range: Last 30 days, grouped by week
- Save & add to dashboard

**Widget 3: Estimations Created**
- Insight type: **Trends**
- Event: `estimation_created`
- Time range: Last 30 days, grouped by week
- Save & add to dashboard

**Widget 4: User Onboarding Funnel**
- Insight type: **Funnel**
- Add funnel created earlier: "User Onboarding Funnel"
- Save & add to dashboard

#### 2. Product Analytics Dashboard

**Purpose:** Track feature usage and product health

**PostHog Setup:**
1. New Dashboard: "Product Health"
2. Add insights:

**Upload Success Rate:**
- Insight type: **Trends**
- Series 1: Event `document_uploaded`, count
- Series 2: Event `document_upload_started`, count
- Formula: `A / B * 100` (percentage)
- Time range: Last 7 days
- Save as: "Upload Success Rate (%)"

**Error Rate by Type:**
- Insight type: **Trends**
- Event: `error_occurred`
- Breakdown by: `error_type` property
- Time range: Last 7 days
- Chart: Stacked bar chart
- Save & add to dashboard

**Top Events:**
- Insight type: **Trends**
- Event: All events
- Aggregation: Total count
- Breakdown by: Event name
- Time range: Last 7 days
- Chart: Bar chart (top 10)
- Save & add to dashboard

#### 3. Feature Flags Dashboard

**Purpose:** Monitor feature flag usage and experiments

**PostHog Setup:**
1. New Dashboard: "Feature Flags & Experiments"
2. Add insights:

**Active Experiments:**
- Navigate to **Experiments** tab
- Pin active experiments to dashboard

**Flag Exposure Rate:**
- Insight type: **Trends**
- Event: `$feature_flag_called`
- Breakdown by: `feature_flag` property
- Time range: Last 7 days
- Save & add to dashboard

### Dashboard-to-Event Instrumentation Matrix

Before creating dashboards, ensure events are instrumented:

| Widget | Event | Required Properties |
|--------|-------|---------------------|
| Active Users | Any event | - |
| New Signups | `user_registered` | - |
| Estimations Created | `estimation_created` | `project_id` |
| Upload Success Rate | `document_uploaded`, `document_upload_started` | `document_category`, `file_type` |
| Error Rates | `error_occurred` | `error_type`, `screen_name` |
| Flag Exposure | `$feature_flag_called` | `feature_flag` (auto-added) |

### Setting Up Alerts

**Critical Metric Alerts:**

**Error Rate Spike:**
1. Open "Error Rate by Type" insight
2. Click **⋯** → **Set up alert**
3. Alert when: Event count > 100 in 1 hour
4. Notification: Email + Slack (configure webhook)
5. Save

**DAU Drop:**
1. Open "Active Users" insight
2. Click **⋯** → **Set up alert**
3. Alert when: Unique users drops > 20% compared to previous day
4. Notification: Email to leadership team
5. Save

**Experiment Completion:**
1. Go to active experiment
2. Enable "Notify when statistically significant"
3. PostHog will email when results are ready

---

## Testing Strategy

### Unit Testing

Use `FakeAnalyticsRepository` in tests to avoid real tracking:

```dart
test('FakeAnalyticsRepository returns success', () async {
  final repo = FakeAnalyticsRepository();
  final result = await repo.track(AnalyticsEvent(name: 'test'));
  expect(result.isRight, true);
});
```

### BLoC Testing

Inject `FakeAnalyticsRepository` when testing BLoCs:

```dart
blocTest<AddCostEstimationBloc, AddCostEstimationState>(
  'tracks event on success',
  build: () => AddCostEstimationBloc(
    ...,
    analyticsRepository: FakeAnalyticsRepository(),
  ),
  act: (bloc) => bloc.add(CreateEstimation(...)),
  expect: () => [loading, success],
);
```

**Note:** Use Fake implementations following project conventions (e.g., `FakeAddCostEstimationUseCase` for test doubles).

### Manual Testing

1. Enable `POSTHOG_DEBUG=true` in `.env.dev`
2. Trigger events in the app
3. Verify in PostHog dashboard under **Activity** → **Events**
4. Test feature flags with email overrides

---

## Migration & Rollout Plan

### Phase 1: Foundation (Week 1-2)

**Tasks:**
- [ ] Add `posthog_flutter` dependency
- [ ] Create analytics library structure (domain/data layers)
- [ ] Implement `AnalyticsRepository` interface and PostHog implementation
- [ ] Add environment configuration (`.env` files)
- [ ] Initialize analytics in `app_bootstrap.dart`
- [ ] Test in dev environment (verify events in PostHog dashboard)

**Testing:**
- Initialize PostHog in dev app
- Track test event manually
- Verify in PostHog dashboard

### Phase 2: Core Events (Week 3-4)

**Tasks:**
- [ ] Add analytics to authentication BLoCs (login, register, logout)
- [ ] Track user identification on login
- [ ] Track estimation CRUD events (create, view, delete, rename)
- [ ] Track project selection and switching
- [ ] Implement screen view tracking in router
- [ ] Create first funnel: User Onboarding

**Testing:**
- Create new user account
- Create estimation
- Verify funnel in PostHog

### Phase 3: Advanced Analytics (Week 5-6)

**Tasks:**
- [ ] Implement group analytics for projects
- [ ] Track estimation activity log events
- [ ] Add event properties (estimation details, project context)
- [ ] Create retention cohorts dashboard
- [ ] Set up alerts for critical metrics

**Testing:**
- Switch between projects
- Verify group association in PostHog
- Verify project-level insights

### Phase 4: Feature Flags (Week 7-8)

**Tasks:**
- [ ] Create first feature flag (e.g., global search)
- [ ] Implement feature flag checks in UI
- [ ] Test gradual rollout (10% → 100%)
- [ ] Document feature flag registry

**Testing:**
- Create flag with 0% rollout
- Verify feature hidden
- Increase to 100%, verify feature shows

### Phase 5: Experiments (Week 9-10)

**Tasks:**
- [ ] Design first A/B test (estimation creation flow)
- [ ] Implement test variants in code
- [ ] Set up experiment in PostHog
- [ ] Run experiment for 2 weeks
- [ ] Analyze results and ship winner

### Phase 6: Production Rollout (Week 11-12)

**Tasks:**
- [ ] Review and optimize event volume (reduce unnecessary events)
- [ ] Set up production PostHog project (separate from dev/qa)
- [ ] Configure production environment variables
- [ ] Enable analytics for 10% of prod users
- [ ] Monitor error rates and performance
- [ ] Gradually increase to 100%

**Go/No-Go Checklist:**
- [ ] Error rate < 1%
- [ ] No performance degradation (app load time)
- [ ] Events appearing correctly in dashboard
- [ ] No PII (personally identifiable information) in event properties
- [ ] GDPR compliance (user consent enforced before identify/track)

### Rollback Plan

If critical issues detected:
1. Set remote kill switch feature flag `analytics_capture_enabled=false` (immediate stop)
2. Call `reset()` for active sessions where required by policy
3. Keep app functional with `FakeAnalyticsRepository` behavior in code paths
4. For hard-disable, set `POSTHOG_ENABLED=false` in environment and ship next release

---

## Best Practices

### Event Tracking

1. **Be specific**: Use descriptive event names (`estimation_created` vs `create`)
2. **Use snake_case**: Consistent naming convention
3. **Include context**: Add relevant properties (IDs, names, counts)
4. **Avoid PII**: Don't track email addresses, phone numbers in event properties (use user properties instead)
5. **Use intent events selectively**: Track intent steps only when needed for UX funnels; use outcome events for KPI reporting

### Performance

1. **Batch events**: PostHog SDK automatically batches, don't call `flush()` excessively
2. **Async tracking**: Always use `await` to avoid blocking UI, but don't wait for completion in critical paths
3. **Cache feature flags**: Check flags once, store in BLoC state, don't check on every build
4. **Lazy initialize**: PostHog initializes in background during app bootstrap

### Privacy & Compliance

1. **Anonymize by default**: Use `personProfiles: PostHogPersonProfiles.identifiedOnly`
2. **Respect opt-out**: Provide analytics opt-out in app settings
3. **No sensitive data**: Don't track passwords, credit cards, SSNs
4. **GDPR compliance**: Enforce consent before identify/track and allow users to request data deletion (PostHog supports this)

### Event Governance

1. Every event must have: owner, description, required properties, and allowed values.
2. Use `event_version` for schema changes that affect dashboards.
3. Deprecate events with a sunset date and migration note.
4. Do not remove old events from dashboards until replacement events are live and validated.

### Feature Flags

1. **Always have fallback**: Handle `null` or error cases
2. **Test both variants**: Test control and test variants before rollout
3. **Clean up old flags**: Archive flags once fully rolled out
4. **Document flags**: Maintain a registry (use this wiki!)

### Dashboards

1. **Start simple**: Create 2-3 core dashboards, expand later
2. **Share with team**: Make dashboards accessible to product, design, exec
3. **Set up alerts**: Don't rely on manual checks
4. **Review weekly**: Schedule recurring dashboard review meetings

### Team Collaboration

1. **Document experiments**: Record hypothesis, results, learnings
2. **Share insights**: Post interesting findings in team chat
3. **Educate team**: Ensure PMs, designers know how to use PostHog
4. **Iterate**: Analytics is never "done", continuously improve tracking

---

## Future Features & Analytics Planning

### Global Search

**Events to Track:**
- `search_performed` - User initiates search
  - Properties: `query`, `search_type` (global/project/estimation), `results_count`
- `search_result_clicked` - User clicks search result
  - Properties: `query`, `result_type` (project/estimation), `result_position`
- `search_filter_applied` - User applies filter
  - Properties: `filter_type`, `filter_value`

**Funnels:**
- Search Engagement: `search_performed` → `search_result_clicked` → `estimation_viewed`

**Metrics:**
- Search usage rate (% of users who search)
- Average results per search
- Click-through rate (CTR) on results
- Zero-result searches (opportunities for improvement)

### Project Switching

**Events to Track:**
- `project_dropdown_clicked` - User opens project switcher
- `project_search_performed` - User searches projects (if search added)
- `project_switched` - User switches to different project
  - Properties: `from_project_id`, `to_project_id`, `switch_method` (dropdown/search)

**Funnels:**
- Project Switch Flow: `project_dropdown_clicked` → `project_switched`

**Group Analytics:**
- Track which projects users switch between most (project affinity)

### File Attachments

**Events to Track:**
- `attachment_button_clicked` - User clicks attach file button
- `file_upload_started` - Upload initiated
  - Properties: `file_type`, `file_size_bytes`
- `file_uploaded` - Upload completed
  - Properties: `file_type`, `file_size_bytes`, `upload_duration_ms`
- `file_upload_failed` - Upload failed
  - Properties: `error_type`, `file_type`, `file_size_bytes`
- `file_downloaded` - User downloads file
- `file_deleted` - User deletes file

**Funnels:**
- Upload Success: `file_upload_started` → `file_uploaded`
- Engagement: `file_uploaded` → `file_downloaded`

**Metrics:**
- Upload success rate
- Average file size
- Most common file types
- Download rate (% of uploaded files that are downloaded)

**Feature Flags:**
- `file_attachments_enabled` - Gate feature by user plan
- `max_file_size_mb` - Remote config for file size limit (payload)

### Cost Files (Templates/Exports)

**Events to Track:**
- `template_selected` - User selects estimation template
  - Properties: `template_id`, `template_name`
- `estimation_exported` - User exports estimation
  - Properties: `export_format` (PDF/Excel/CSV), `estimation_id`
- `export_shared` - User shares exported file
  - Properties: `share_method` (email/link)

**A/B Tests:**
- Test export formats: PDF vs Excel (which is used more?)
- Test template UI: List vs gallery

---

## PostHog Feature Flag Registry

Maintain this table for all active feature flags:

| Flag Key | Type | Purpose | Owner | Status | Created | Notes |
|----------|------|---------|-------|--------|---------|-------|
| `global_search_enabled` | Boolean | Gradual rollout of global search | @dev-team | Active | 2026-03-23 | Currently 10% rollout |
| `file_attachments_enabled` | Boolean | Premium feature gate | @product | Active | 2026-03-23 | Plan-based access |
| `estimation_page_size` | Multivariate | Optimize pagination performance | @engineering | Testing | 2026-03-23 | Variants: 20/30/50 |
| `estimation_templates_config` | JSON Payload | Remote template configuration | @product | Planned | - | Design in progress |

**Updating this registry:**
- Add row when creating new flag in PostHog
- Update status when rolling out or archiving
- Include rollout percentage in notes

---

## Appendix

### PostHog Resources

- **Official Docs**: https://posthog.com/docs
- **Flutter SDK**: https://posthog.com/docs/libraries/flutter
- **Feature Flags**: https://posthog.com/docs/feature-flags
- **Experiments**: https://posthog.com/docs/experiments
- **Group Analytics**: https://posthog.com/docs/product-analytics/group-analytics

### Sample PostHog Event Schema

```json
{
  "event": "estimation_created",
  "properties": {
    "estimation_id": "550e8400-e29b-41d4-a716-446655440000",
    "estimation_name": "Kitchen Remodel",
    "project_id": "660e8400-e29b-41d4-a716-446655440000",
    "total_cost": 15000.50,
    "item_count": 25,
    "is_locked": false,
    "creation_method": "manual",
    "$group_project": "660e8400-e29b-41d4-a716-446655440000"
  },
  "timestamp": "2026-03-23T10:30:00Z",
  "distinct_id": "user-123",
  "$set": {
    "email_hash": "sha256:...",
    "plan_type": "premium"
  }
}
```

### Cost Estimation

**PostHog Pricing (as of 2025):**
- **Free Tier**: 1M events/month, unlimited feature flags
- **Paid**: $0.00045/event (after free tier)
- **Self-hosted**: Free (open-source), requires infrastructure

**Estimated Event Volume for Construculator:**
- 1,000 MAU (Monthly Active Users)
- ~30 events per user per month (login, create/view estimations, navigate)
- **Total**: ~30,000 events/month (well within free tier)

**Scaling:**
- 10,000 MAU = 300,000 events/month (still free tier)
- 100,000 MAU = 3M events/month (~$900/month)

---

**End of PostHog Integration Guide**

For questions or suggestions, contact the development team.
