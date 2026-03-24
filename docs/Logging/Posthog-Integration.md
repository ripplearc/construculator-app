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

1. **All-in-one**: Replaces multiple tools (analytics, feature flags, experiments)
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

1. **Testability**: Isolate analytics in tests using `NoOpAnalyticsRepository`
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
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

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

  /// Get feature flag value by key.
  ///
  /// Returns null if flag doesn't exist or SDK not initialized.
  Future<Either<Failure, bool?>> isFeatureEnabled(String featureFlagKey);

  /// Get feature flag variant (for multivariate flags).
  ///
  /// Returns variant key (e.g., 'control', 'test', 'variant-a').
  Future<Either<Failure, String?>> getFeatureFlagVariant(String featureFlagKey);

  /// Get feature flag payload (JSON data attached to flag).
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(
    String featureFlagKey,
  );

  /// Reload feature flags from server.
  ///
  /// Useful after user properties change or login.
  Future<Either<Failure, void>> reloadFeatureFlags();

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

### Domain Layer: Analytics Event Entity

**File:** `lib/libraries/analytics/domain/entities/analytics_event.dart`

```dart
import 'package:equatable/equatable.dart';

/// Represents an analytics event to be tracked.
///
/// Immutable entity that encapsulates event name and properties.
class AnalyticsEvent extends Equatable {
  const AnalyticsEvent({
    required this.name,
    this.properties = const {},
  });

  /// Event name (e.g., 'estimation_created', 'project_switched').
  final String name;

  /// Event properties (custom metadata).
  final Map<String, dynamic> properties;

  @override
  List<Object?> get props => [name, properties];

  @override
  String toString() => 'AnalyticsEvent(name: $name, properties: $properties)';
}
```

### Domain Layer: User Properties Entity

**File:** `lib/libraries/analytics/domain/entities/analytics_user_properties.dart`

```dart
import 'package:equatable/equatable.dart';

/// User properties for analytics identification.
class AnalyticsUserProperties extends Equatable {
  const AnalyticsUserProperties({
    this.email,
    this.name,
    this.createdAt,
    this.companyName,
    this.role,
    this.planType,
    this.custom = const {},
  });

  final String? email;
  final String? name;
  final DateTime? createdAt;
  final String? companyName;
  final String? role;
  final String? planType;

  /// Additional custom properties.
  final Map<String, dynamic> custom;

  Map<String, dynamic> toMap() {
    return {
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (companyName != null) 'company_name': companyName,
      if (role != null) 'role': role,
      if (planType != null) 'plan_type': planType,
      ...custom,
    };
  }

  @override
  List<Object?> get props => [email, name, createdAt, companyName, role, planType, custom];
}
```

### Data Layer: PostHog Repository Implementation

**File:** `lib/libraries/analytics/data/repositories/analytics_repository_impl.dart`

```dart
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({
    required String apiKey,
    required String host,
    required bool debug,
  })  : _apiKey = apiKey,
        _host = host,
        _debug = debug;

  final String _apiKey;
  final String _host;
  final bool _debug;

  static final _logger = AppLogger().tag('AnalyticsRepositoryImpl');

  bool _initialized = false;

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      if (_initialized) {
        _logger.warning('PostHog already initialized, skipping');
        return const Right(null);
      }

      final config = PostHogConfig(_apiKey);
      config.host = _host;
      config.debug = _debug;
      config.captureApplicationLifecycleEvents = true;

      // Person profiles: only create for identified users
      config.personProfiles = PostHogPersonProfiles.identifiedOnly;

      // Enable session replay (optional - adds app size)
      // config.sessionReplay = true;
      // config.sessionReplayConfig = PostHogSessionReplayConfig(
      //   maskAllTexts: false,
      //   maskAllImages: false,
      //   captureNetworkTelemetry: true,
      // );

      await Posthog().setup(config);

      _initialized = true;
      _logger.info('PostHog initialized successfully');

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize PostHog', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Analytics initialization failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> track(AnalyticsEvent event) async {
    try {
      if (!_initialized) {
        _logger.warning('PostHog not initialized, skipping event: ${event.name}');
        return const Right(null);
      }

      await Posthog().capture(
        eventName: event.name,
        properties: event.properties,
      );

      _logger.debug('Tracked event: ${event.name}');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to track event: ${event.name}', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Event tracking failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  }) async {
    try {
      if (!_initialized) {
        _logger.warning('PostHog not initialized, skipping identify');
        return const Right(null);
      }

      await Posthog().identify(
        userId: userId,
        userProperties: properties.toMap(),
      );

      _logger.info('Identified user: $userId');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to identify user', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('User identification failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reset() async {
    try {
      if (!_initialized) {
        return const Right(null);
      }

      await Posthog().reset();
      _logger.info('Analytics reset (user logged out)');

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to reset analytics', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Analytics reset failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setUserProperties(
    AnalyticsUserProperties properties,
  ) async {
    try {
      if (!_initialized) {
        return const Right(null);
      }

      await Posthog().setPersonPropertiesForFlags(properties.toMap());
      _logger.debug('Updated user properties');

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to set user properties', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Set properties failed: $e'));
    }
  }

  @override
  Future<Either<Failure, bool?>> isFeatureEnabled(String featureFlagKey) async {
    try {
      if (!_initialized) {
        return const Right(null);
      }

      final isEnabled = await Posthog().isFeatureEnabled(featureFlagKey);
      _logger.debug('Feature flag "$featureFlagKey": $isEnabled');

      return Right(isEnabled);
    } catch (e, stackTrace) {
      _logger.error('Failed to check feature flag: $featureFlagKey', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Feature flag check failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getFeatureFlagVariant(String featureFlagKey) async {
    try {
      if (!_initialized) {
        return const Right(null);
      }

      final variant = await Posthog().getFeatureFlagVariant(featureFlagKey);
      _logger.debug('Feature flag variant "$featureFlagKey": $variant');

      return Right(variant);
    } catch (e, stackTrace) {
      _logger.error('Failed to get feature flag variant: $featureFlagKey', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Feature flag variant failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(
    String featureFlagKey,
  ) async {
    try {
      if (!_initialized) {
        return const Right(null);
      }

      final payload = await Posthog().getFeatureFlagPayload(featureFlagKey);
      _logger.debug('Feature flag payload "$featureFlagKey": $payload');

      return Right(payload);
    } catch (e, stackTrace) {
      _logger.error('Failed to get feature flag payload: $featureFlagKey', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Feature flag payload failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reloadFeatureFlags() async {
    try {
      if (!_initialized) {
        return const Right(null);
      }

      await Posthog().reloadFeatureFlags();
      _logger.debug('Reloaded feature flags');

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to reload feature flags', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Reload feature flags failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? properties,
  }) async {
    try {
      if (!_initialized) {
        return const Right(null);
      }

      await Posthog().group(
        groupType: groupType,
        groupKey: groupKey,
        groupProperties: properties,
      );

      _logger.debug('Set group: $groupType = $groupKey');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to set group', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Group analytics failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> flush() async {
    try {
      if (!_initialized) {
        return const Right(null);
      }

      await Posthog().flush();
      _logger.debug('Flushed analytics events');

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to flush events', error: e, stackTrace: stackTrace);
      return Left(UnexpectedFailure('Flush failed: $e'));
    }
  }
}
```

### Data Layer: No-Op Repository (for Testing)

**File:** `lib/libraries/analytics/data/repositories/no_op_analytics_repository.dart`

```dart
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// No-op implementation for testing or when analytics is disabled.
class NoOpAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<Either<Failure, void>> initialize() async => const Right(null);

  @override
  Future<Either<Failure, void>> track(AnalyticsEvent event) async => const Right(null);

  @override
  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> reset() async => const Right(null);

  @override
  Future<Either<Failure, void>> setUserProperties(
    AnalyticsUserProperties properties,
  ) async =>
      const Right(null);

  @override
  Future<Either<Failure, bool?>> isFeatureEnabled(String featureFlagKey) async =>
      const Right(null);

  @override
  Future<Either<Failure, String?>> getFeatureFlagVariant(String featureFlagKey) async =>
      const Right(null);

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(
    String featureFlagKey,
  ) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> reloadFeatureFlags() async => const Right(null);

  @override
  Future<Either<Failure, void>> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? properties,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> flush() async => const Right(null);
}
```

### Module Configuration

**File:** `lib/libraries/analytics/analytics_module.dart`

```dart
import 'package:construculator/libraries/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AnalyticsModule extends Module {
  @override
  List<Module> get imports => [];

  @override
  void binds(i) {
    // Check if analytics is enabled in environment
    final enabled = dotenv.env['POSTHOG_ENABLED']?.toLowerCase() == 'true';

    if (enabled) {
      final apiKey = dotenv.env['POSTHOG_API_KEY'] ?? '';
      final host = dotenv.env['POSTHOG_HOST'] ?? 'https://us.i.posthog.com';
      final debug = dotenv.env['POSTHOG_DEBUG']?.toLowerCase() == 'true';

      // Fail closed: if key is missing, disable analytics safely.
      if (apiKey.isEmpty) {
        i.addLazySingleton<AnalyticsRepository>(NoOpAnalyticsRepository.new);
        return;
      }

      i.addLazySingleton<AnalyticsRepository>(
        () => AnalyticsRepositoryImpl(
          apiKey: apiKey,
          host: host,
          debug: debug,
        ),
      );
    } else {
      i.addLazySingleton<AnalyticsRepository>(NoOpAnalyticsRepository.new);
    }
  }

  @override
  void routes(r) {}
}
```

### App Bootstrap Integration

**File:** `lib/app/app_bootstrap.dart` (update)

```dart
import 'package:construculator/libraries/analytics/analytics_module.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
// ... existing imports

class AppBootstrap {
  static Future<void> initialize() async {
    // ... existing initialization code

    // Gate analytics initialization with persisted consent/opt-out state.
    // Example:
    // final hasConsent = await _consentService.hasAnalyticsConsent();
    // if (!hasConsent) return;

    // Initialize analytics
    final analyticsRepository = Modular.get<AnalyticsRepository>();
    final result = await analyticsRepository.initialize();

    result.fold(
      (failure) => _logger.warning('Analytics initialization failed: $failure'),
      (_) => _logger.info('Analytics initialized successfully'),
    );
  }
}
```

**File:** `lib/app/app_module.dart` (update)

```dart
import 'package:construculator/libraries/analytics/analytics_module.dart';
// ... existing imports

class AppModule extends Module {
  @override
  List<Module> get imports => [
    // ... existing modules
    AnalyticsModule(),
  ];

  // ... rest of module
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

#### Example 1: Tracking in BLoC (Estimation Creation)

**File:** `lib/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart`

```dart
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
// ... other imports

class AddCostEstimationBloc extends Bloc<AddCostEstimationEvent, AddCostEstimationState> {
  AddCostEstimationBloc({
    required AddCostEstimationUseCase useCase,
    required AnalyticsRepository analyticsRepository,  // Inject dependency
  })  : _useCase = useCase,
        _analyticsRepository = analyticsRepository,
        super(const AddCostEstimationState.initial()) {
    on<CreateEstimation>(_onCreateEstimation);
  }

  final AddCostEstimationUseCase _useCase;
  final AnalyticsRepository _analyticsRepository;

  Future<void> _onCreateEstimation(
    CreateEstimation event,
    Emitter<AddCostEstimationState> emit,
  ) async {
    emit(const AddCostEstimationState.loading());

    final result = await _useCase(
      estimationName: event.estimationName,
      projectId: event.projectId,
    );

    result.fold(
      (failure) => emit(AddCostEstimationState.error(failure)),
      (estimation) {
        // Track successful creation
        _analyticsRepository.track(
          AnalyticsEvent(
            name: 'estimation_created',
            properties: {
              'estimation_id': estimation.id,
              'estimation_name': estimation.name,
              'project_id': estimation.projectId,
              'creation_method': 'manual',  // vs 'template', 'duplicate'
            },
          ),
        );

        emit(AddCostEstimationState.success(estimation));
      },
    );
  }
}
```

Update module binding:

```dart
// In EstimationModule
i.add<AddCostEstimationBloc>(
  () => AddCostEstimationBloc(
    useCase: i.get(),
    analyticsRepository: i.get(),  // Inject from AnalyticsModule
  ),
);
```

#### Example 2: Tracking User Identification (Login)

**File:** `lib/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart`

```dart
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
// ... other imports

class LoginWithEmailBloc extends Bloc<LoginWithEmailEvent, LoginWithEmailState> {
  LoginWithEmailBloc({
    required LoginWithEmailUseCase useCase,
    required AnalyticsRepository analyticsRepository,
  })  : _useCase = useCase,
        _analyticsRepository = analyticsRepository,
        super(const LoginWithEmailState.initial()) {
    on<Login>(_onLogin);
  }

  final LoginWithEmailUseCase _useCase;
  final AnalyticsRepository _analyticsRepository;

  Future<void> _onLogin(
    Login event,
    Emitter<LoginWithEmailState> emit,
  ) async {
    emit(const LoginWithEmailState.loading());

    final result = await _useCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(LoginWithEmailState.error(failure)),
      (userProfile) async {
        // Identify user in analytics
        await _analyticsRepository.identify(
          userId: userProfile.id,
          properties: AnalyticsUserProperties(
            email: userProfile.email,
            name: userProfile.name,
            createdAt: userProfile.createdAt,
            role: userProfile.role,
          ),
        );

        // Track login event
        await _analyticsRepository.track(
          const AnalyticsEvent(
            name: 'user_logged_in',
            properties: {
              'login_method': 'email',
            },
          ),
        );

        emit(LoginWithEmailState.success(userProfile));
      },
    );
  }
}
```

#### Example 3: Screen View Tracking (Automatic)

**File:** `lib/libraries/router/app_router_impl.dart` (update)

```dart
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter/material.dart';
// ... other imports

class AppRouterImpl implements AppRouter {
  AppRouterImpl({required AnalyticsRepository analyticsRepository})
      : _analyticsRepository = analyticsRepository;

  final AnalyticsRepository _analyticsRepository;

  Map<String, dynamic> _safeNavigationProperties(
    String route,
    Map<String, dynamic>? arguments,
  ) {
    // Keep payload bounded and avoid leaking sensitive navigation arguments.
    return {
      'screen_name': route,
      if (arguments?['source'] is String) 'source': arguments?['source'],
      if (arguments?['entry_point'] is String) 'entry_point': arguments?['entry_point'],
      'has_arguments': arguments?.isNotEmpty ?? false,
    };
  }

  @override
  void navigate(String route, {Map<String, dynamic>? arguments}) {
    // Track screen view
    _analyticsRepository.track(
      AnalyticsEvent(
        name: 'screen_viewed',
        properties: _safeNavigationProperties(route, arguments),
      ),
    );

    Modular.to.pushNamed(route, arguments: arguments);
  }
}
```

#### Example 4: Group Analytics (Project Selection)

**File:** `lib/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart`

```dart
Future<void> _onSelectProject(
  SelectProject event,
  Emitter<ProjectDropdownState> emit,
) async {
  // ... existing logic

  // Set group for B2B analytics
  await _analyticsRepository.group(
    groupType: 'project',
    groupKey: event.projectId,
    properties: {
      'project_name': project.name,
      'project_status': project.status,
      'created_at': project.createdAt.toIso8601String(),
    },
  );

  // Track project switch event
  await _analyticsRepository.track(
    AnalyticsEvent(
      name: 'project_switched',
      properties: {
        'project_id': event.projectId,
        'project_name': project.name,
      },
    ),
  );
}
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
| **Revenue** | `subscription_started`, `plan_upgraded` | MRR, ARPU, Conversion rate |
| **Referral** | `user_invited`, `invite_accepted` | Referral rate, Viral coefficient |

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

#### 2. User Segmentation: Premium Features

**Scenario:** Show file attachment feature only to premium users.

**Flag Configuration:**

**In PostHog Dashboard:**
1. Key: `file_attachments_enabled`
2. Release conditions:
   - **User property**: `plan_type` = `premium` OR `enterprise` → `true`
   - **Default**: `false`

**In Code:**

```dart
// In EstimationDetailsPage
Future<void> _checkFileAttachmentAccess() async {
  final result = await _analyticsRepository.isFeatureEnabled('file_attachments_enabled');

  result.fold(
    (_) => setState(() => _canAttachFiles = false),
    (enabled) => setState(() => _canAttachFiles = enabled ?? false),
  );
}

// In UI
if (_canAttachFiles)
  IconButton(
    icon: const Icon(Icons.attach_file),
    onPressed: _showAttachmentDialog,
  )
else
  Tooltip(
    message: 'Upgrade to Premium for file attachments',
    child: IconButton(
      icon: const Icon(Icons.lock),
      onPressed: _showUpgradeDialog,
    ),
  ),
```

#### 3. Remote Configuration: Pagination Size

**Scenario:** Adjust pagination size without app update to optimize performance.

**Flag Configuration:**

**In PostHog Dashboard:**
1. Key: `estimation_page_size`
2. Type: **Boolean** (use variants for multiple values)
3. Variants:
   - `control`: 20 items
   - `variant_30`: 30 items
   - `variant_50`: 50 items
4. Release:
   - 33% each variant

**In Code:**

```dart
// In CostEstimationRepositoryImpl
Future<int> _getPageSize() async {
  final result = await _analyticsRepository.getFeatureFlagVariant('estimation_page_size');

  return result.fold(
    (_) => 20,  // Default fallback
    (variant) {
      switch (variant) {
        case 'variant_30':
          return 30;
        case 'variant_50':
          return 50;
        default:
          return 20;
      }
    },
  );
}
```

#### 4. JSON Payload: Complex Configuration

**Scenario:** Configure new estimation template feature with complex JSON data.

**Flag Configuration:**

**In PostHog Dashboard:**
1. Key: `estimation_templates_config`
2. Payload (JSON):
```json
{
  "enabled": true,
  "templates": [
    {
      "id": "residential_kitchen",
      "name": "Residential Kitchen Remodel",
      "default_items": [
        {"name": "Cabinets", "category": "material"},
        {"name": "Countertops", "category": "material"},
        {"name": "Installation", "category": "labor"}
      ]
    },
    {
      "id": "bathroom_basic",
      "name": "Basic Bathroom Renovation",
      "default_items": [
        {"name": "Fixtures", "category": "material"},
        {"name": "Tiling", "category": "material"}
      ]
    }
  ]
}
```

**In Code:**

```dart
// In EstimationTemplatesWidget
Future<List<EstimationTemplate>> _loadTemplates() async {
  final result = await _analyticsRepository.getFeatureFlagPayload('estimation_templates_config');

  return result.fold(
    (_) => [],  // No templates
    (payload) {
      if (payload == null || payload['enabled'] != true) {
        return [];
      }

      final templatesJson = payload['templates'] as List<dynamic>;
      return templatesJson
          .map((json) => EstimationTemplate.fromJson(json))
          .toList();
    },
  );
}
```

#### 5. Environment-Specific Flags

**Scenario:** Enable debug logging or features only in dev/QA environments.

**Flag Configuration:**

**In PostHog Dashboard:**
1. Key: `verbose_logging_enabled`
2. Release conditions:
   - **User property**: `environment` = `dev` OR `qa` → `true`
   - **Default**: `false`

**In Code:**

```dart
// Set environment as user property on app start
await _analyticsRepository.setUserProperties(
  AnalyticsUserProperties(
    custom: {
      'environment': dotenv.env['ENVIRONMENT'], // 'dev', 'qa', 'prod'
    },
  ),
);

// Check flag in logging
Future<void> _logDebugInfo(String message) async {
  final result = await _analyticsRepository.isFeatureEnabled('verbose_logging_enabled');
  final shouldLog = result.fold((_) => false, (enabled) => enabled ?? false);

  if (shouldLog) {
    _logger.debug(message);
  }
}
```

### Feature Flag Best Practices

1. **Always provide fallback values**: Handle `null` or error states gracefully
2. **Cache flag values**: Don't check flags on every render (use BLoC or provider)
3. **Track flag exposures**: Log when users see feature variants
4. **Clean up old flags**: Archive flags once features are fully rolled out
5. **Use consistent naming**: `feature_name_enabled` or `feature_name_config`
6. **Document flags**: Keep a registry of active flags and their purpose

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

**Hypothesis:** A guided wizard for estimation creation will increase completion rate vs. single-step dialog.

**Variants:**
- **Control**: Current single-step dialog (name + create)
- **Test**: Multi-step wizard (name → select template → configure → create)

**Setup in PostHog:**

1. Navigate to **Experiments** → **New Experiment**
2. Name: "Estimation Creation Wizard Test"
3. Feature flag key: `estimation_creation_flow`
4. Type: **Product experiment**
5. Participants: **All users** (or filter by property)
6. Variants:
   - `control` (50%)
   - `wizard` (50%)
7. Goal metric: `estimation_created` event
8. Secondary metrics:
   - `estimation_viewed` (engagement)
   - `estimation_renamed` (quality indicator)
9. Minimum acceptable improvement: **5%**
10. Recommended running time: **2 weeks** (PostHog calculates based on traffic)

**Implementation:**

```dart
// In AddCostEstimationBloc or page
Future<void> _determineCreationFlow() async {
  final result = await _analyticsRepository.getFeatureFlagVariant('estimation_creation_flow');

  final variant = result.fold((_) => 'control', (v) => v ?? 'control');

  // Track exposure (PostHog tracks automatically, but explicit tracking is clearer)
  await _analyticsRepository.track(
    AnalyticsEvent(
      name: '\$feature_flag_called',
      properties: {
        'feature_flag': 'estimation_creation_flow',
        'variant': variant,
      },
    ),
  );

  if (variant == 'wizard') {
    _showWizardDialog();
  } else {
    _showSingleStepDialog();
  }
}

// Track completion for both variants
Future<void> _onEstimationCreated(CostEstimate estimation) async {
  await _analyticsRepository.track(
    AnalyticsEvent(
      name: 'estimation_created',
      properties: {
        'creation_flow': _currentVariant,  // 'control' or 'wizard'
        'estimation_id': estimation.id,
      },
    ),
  );
}
```

**Analyzing Results in PostHog:**

After 2 weeks, navigate to **Experiments** → **Estimation Creation Wizard Test**:

- **Conversion Rate**: Control: 65%, Wizard: 72% → **+10.8% improvement**
- **Statistical Significance**: 95% confidence (p < 0.05)
- **Recommendation**: Ship wizard variant (click "Ship variant")

**Shipping the Winner:**

1. In PostHog, click **Ship variant** → Select `wizard`
2. Feature flag `estimation_creation_flow` now returns `wizard` for 100% users
3. (Optional) Remove control code path in next app release

### Additional A/B Test Ideas

#### 1. Onboarding Tutorial Test

**Variants:**
- `control`: No tutorial
- `tooltip`: Inline tooltips on first visit
- `modal`: Full-screen tutorial modal

**Goal:** Measure `estimation_created` within 7 days of signup

#### 2. Estimation List Layout Test

**Variants:**
- `control`: List view
- `grid`: Grid card view

**Goal:** Measure `estimation_viewed` clicks

#### 3. Pricing Page CTA Test

**Variants:**
- `control`: "Start Free Trial"
- `test_a`: "Get Started Free"
- `test_b`: "Try 14 Days Free"

**Goal:** Measure `subscription_started`

### Experiment Best Practices

1. **Run one experiment at a time** (per feature area) to avoid interaction effects
2. **Calculate required sample size** before starting (PostHog does this automatically)
3. **Don't stop early**: Wait for statistical significance + recommended runtime
4. **Track secondary metrics**: Ensure you're not sacrificing other KPIs
5. **Document learnings**: Record results in wiki/notion for future reference

---

## Group Analytics (B2B)

Group analytics is critical for B2B SaaS to understand **account-level** behavior (projects, companies) vs individual users.

### Use Cases

1. **Project-level analytics**: Which projects have the most estimations? Which are active vs dormant?
2. **Company-level analytics** (future): Track usage across all users in a company
3. **Team analytics**: How do teams collaborate on estimations?
4. **Account health scoring**: Identify at-risk projects/companies

### Implementation

#### Setting Group Type on Project Selection

**File:** `lib/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart`

```dart
Future<void> _onSelectProject(
  SelectProject event,
  Emitter<ProjectDropdownState> emit,
) async {
  // ... fetch project logic

  // Set project as group
  await _analyticsRepository.group(
    groupType: 'project',
    groupKey: project.id,
    properties: {
      'project_name': project.name,
      'project_status': project.status.name,
      'created_at': project.createdAt.toIso8601String(),
      'estimation_count': project.estimationCount ?? 0,
      'total_cost_value': project.totalValue ?? 0,
    },
  );

  emit(ProjectDropdownState.selected(project));
}
```

#### Tracking Events with Group Context

All subsequent events automatically associated with the active project group:

```dart
// User creates estimation while project group is set
await _analyticsRepository.track(
  AnalyticsEvent(
    name: 'estimation_created',
    properties: {
      'estimation_id': estimation.id,
      // PostHog automatically includes: '$group_project': projectId
    },
  ),
);
```

### Dashboard Setup for Group Analytics

**In PostHog Dashboard:**

1. Navigate to **Settings** → **Project** → **Group Analytics**
2. Add group type: `project`
3. Display name: "Project"

**Create Project Insights:**

1. **Most Active Projects**:
   - Go to **Product Analytics** → **Insights** → **Trends**
   - Event: `estimation_created`
   - Breakdown by: `$group_project`
   - Time range: Last 30 days

2. **Project Health Dashboard**:
   - Event: `estimation_viewed` OR `estimation_created`
   - Filter: `$group_project` is set
   - Breakdown: By project
   - Visualization: Table with columns:
     - Project name
     - Total events (activity level)
     - Unique users (collaboration)
     - Last active date

3. **Dormant Projects**:
   - Event: Any event
   - Filter: `$group_project` is set
   - Filter: Last event > 30 days ago
   - Alert: Notify when project goes dormant

### Company-Level Groups (Future)

When multi-company support is added:

```dart
// On user login, set company group
await _analyticsRepository.group(
  groupType: 'company',
  groupKey: user.companyId,
  properties: {
    'company_name': user.companyName,
    'plan_type': user.planType,
    'user_count': companyUserCount,
    'mrr': monthlyRevenue,
  },
);

// Events now automatically tagged with both:
// - $group_project: current project
// - $group_company: user's company
```

**Company Dashboard Insights:**
- ARR by company
- Feature adoption by company
- Expansion opportunities (companies using > 80% of features)

---

## Dashboard Configuration

### PostHog Dashboard Organization

Create the following dashboards in PostHog for comprehensive analytics:

#### 1. Executive Dashboard

**Widgets:**
- **Total Users** (Insight: Unique users, last 30 days)
- **Active Users** (Insight: WAU, MAU trends)
- **New Signups** (Insight: `user_registered`, last 30 days, trended)
- **Estimations Created** (Insight: `estimation_created`, last 30 days, trended)
- **User Retention** (Insight: Retention cohorts by signup week)
- **Top Projects** (Insight: `estimation_created` grouped by `$group_project`, top 10)

#### 2. Product Analytics Dashboard

**Widgets:**
- **Feature Adoption Funnel** (Funnel: User onboarding)
- **Upload Documents Funnel** (Funnel: EST-023 upload documents flow)
- **Top Events** (Insight: All events, last 7 days, bar chart)
- **Average Estimations per User** (Formula: `estimation_created` / unique users)
- **Search Usage** (Insight: `search_performed`, trended)
- **Document Upload Success Rate** (Insight: `document_uploaded` / `document_upload_started`)

#### 3. Growth Dashboard

**Widgets:**
- **Acquisition Channels** (Insight: `user_registered` breakdown by `utm_source`)
- **Activation Rate** (Formula: Users with `estimation_created` / `user_registered` in last 7 days)
- **AARRR Metrics** (Multiple insights for Acquisition, Activation, Retention, Revenue, Referral)
- **Viral Coefficient** (Formula: `invite_accepted` / `user_invited`)

#### 4. Feature Flags Dashboard

**Widgets:**
- **Active Feature Flags** (List all flags with status)
- **Flag Exposure** (Insight: `$feature_flag_called`, breakdown by flag name)
- **Experiment Results** (Link to active experiments)
- **Flag Usage by User Segment** (Breakdown: `$feature_flag_called` by user properties)

#### 5. Performance Dashboard

**Widgets:**
- **Average Load Time** (Insight: `screen_loaded`, property: `load_time_ms`, aggregation: average)
- **Error Rates** (Insight: `error_occurred`, breakdown by `error_type`)
- **API Response Times** (Insight: custom event `api_call_completed`, property: `duration_ms`)
- **Session Duration** (Insight: Session recordings, average duration)

### Dashboard-to-Event Instrumentation Matrix (Required)

Before publishing dashboards, confirm each widget has a concrete event source in code:

| Dashboard Widget | Event | Required Properties | Owner |
|------------------|-------|---------------------|-------|
| Average Load Time | `screen_loaded` | `screen_name`, `load_time_ms` | Mobile |
| Error Rates | `error_occurred` | `error_type`, `screen_name` | Mobile |
| API Response Times | `api_call_completed` | `endpoint_group`, `duration_ms`, `status_code_bucket` | Mobile |
| Upload Completion | `document_uploaded` | `document_category`, `file_type` | Mobile |

If a widget has no mapped event/properties, do not add it to dashboards yet.

### Creating a Dashboard

**In PostHog:**
1. Navigate to **Dashboards** → **New Dashboard**
2. Name: "Executive Dashboard"
3. Click **Add Insight**
4. Configure insight (event, filters, visualization)
5. Click **Save & Add to Dashboard**
6. Repeat for all widgets
7. Arrange widgets with drag-and-drop
8. Click **Share** to share with team

### Alerts & Monitoring

Set up alerts for critical metrics:

**In PostHog:**
1. Navigate to **Insights** → Create insight (e.g., "Error Rate")
2. Click **⋯** → **Set up alert**
3. Configure:
   - Threshold: Error count > 100 in 1 hour
   - Notification: Email, Slack webhook
4. Save

**Recommended Alerts:**
- Error rate spike (> 5% of sessions)
- Drop in daily active users (> 20% decrease)
- Experiment reaches significance
- Feature flag exposure anomaly

---

## Testing Strategy

### Unit Testing Analytics

**File:** `test/libraries/analytics/data/repositories/no_op_analytics_repository_test.dart`

```dart
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoOpAnalyticsRepository', () {
    late NoOpAnalyticsRepository repository;

    setUp(() {
      repository = NoOpAnalyticsRepository();
    });

    test('initialize returns Right', () async {
      final result = await repository.initialize();
      expect(result.isRight, true);
    });

    test('track event returns Right', () async {
      const event = AnalyticsEvent(name: 'test_event');
      final result = await repository.track(event);
      expect(result.isRight, true);
    });
  });
}
```

### BLoC Testing with Analytics

**File:** `test/features/estimation/presentation/bloc/add_cost_estimation_bloc_test.dart`

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddCostEstimationBloc', () {
    late AddCostEstimationUseCase fakeUseCase;
    late AnalyticsRepository analyticsRepository;

    setUp(() {
      fakeUseCase = FakeAddCostEstimationUseCase();
      analyticsRepository = NoOpAnalyticsRepository();
    });

    blocTest<AddCostEstimationBloc, AddCostEstimationState>(
      'emits success and tracks event when creation succeeds',
      build: () => AddCostEstimationBloc(
        useCase: fakeUseCase,
        analyticsRepository: analyticsRepository,
      ),
      act: (bloc) => bloc.add(const CreateEstimation(
        estimationName: 'Test Estimation',
        projectId: 'project-123',
      )),
      expect: () => [
        const AddCostEstimationState.loading(),
        isA<AddCostEstimationState>().having(
          (s) => s.maybeMap(success: (_) => true, orElse: () => false),
          'is success',
          true,
        ),
      ],
      verify: (_) {},
    );
  });
}
```

**Testing note**:
- Keep analytics tests deterministic: use no-op/fake implementations for unit and widget tests.
- Reserve SDK-level verification for manual QA in dev/qa environments.

### Integration Testing

Test analytics in integration tests with no-op repository:

**File:** `integration_test/app_test.dart`

```dart
// Override AnalyticsModule to use NoOpAnalyticsRepository
await app.main();  // App uses NoOp in test environment

// Perform test actions
await tester.tap(find.text('Create Estimation'));
await tester.pumpAndSettle();

// Assert UI changes (analytics happens in background, don't assert on it)
expect(find.text('Estimation Created'), findsOneWidget);
```

### Manual Testing in Dashboard

1. **Enable debug mode** in dev environment (`.env.dev`):
   ```env
   POSTHOG_DEBUG=true
   ```

2. **Trigger events** in app (create estimation, login, etc.)

3. **Verify in PostHog**:
   - Navigate to **Activity** → **Events**
   - Filter by `distinct_id` (your user ID)
   - Verify events appear with correct properties

4. **Test feature flags**:
   - Create test flag in PostHog
   - Set override for your email
   - Reload app and verify flag value in app

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
3. Keep app functional with `NoOpAnalyticsRepository` behavior in code paths
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
