# Sentry Integration Guide

This document covers Sentry integration for error tracking and crash reporting in the Construculator Flutter application, integrated with our existing `AppLogger`.

---

## 1. Overview

Sentry provides real-time error tracking and crash reporting for our Flutter application. It automatically captures unhandled exceptions and allows us to manually report errors through our existing `AppLogger` infrastructure.

**What Sentry gives us:**
- Automatic crash reports for unhandled exceptions
- Error tracking integrated with `AppLogger.error()` and `AppLogger.omg()`
- Breadcrumb trails via `AppLogger.info()` and `AppLogger.warning()`
- Stack traces with source maps
- Release tracking to know which version has issues
- User context (who experienced the error)

---

## 2. Installation

Add Sentry to `pubspec.yaml`:

```yaml
dependencies:
  sentry_flutter: ^9.14.0
```

---

## 3. Configuration

### 3.1 Environment Variables

Add `SENTRY_DSN` to environment files.

`SENTRY_DSN` is the Sentry project connection string (Data Source Name) that tells the SDK where to send events. When it is empty, the SDK is disabled.

## Finding SENTRY_DSN in the Dashboard

1. Log in to your Sentry account at https://sentry.io
2. Navigate to **Settings** → **Projects**
3. Select your project
4. Go to **Client Keys (DSN)** in the left sidebar
5. Copy the DSN value displayed under "Your DSN"

The DSN configures the protocol, public key, server address, and project identifier. It is composed of the following parts:

{PROTOCOL}://{PUBLIC_KEY}:{SECRET_KEY}@{HOST}{PATH}/{PROJECT_ID}

```dotenv
# .env.dev - Empty DSN disables Sentry
SENTRY_DSN=

# .env.qa
SENTRY_DSN=https://your-qa-dsn@sentry.io/project

# .env.prod
SENTRY_DSN=https://your-prod-dsn@sentry.io/project
```

> ⚠️ **Never commit `.env.qa` or `.env.prod` files to source control.**

### 3.1.1 CI/CD (Codemagic) Setup

Use **Environment Groups** in Codemagic to organize secure variables per environment, then generate the complete env file during the build.

**Setup:**
1. Create environment groups in Codemagic (e.g., `construculator_dev`, `construculator_qa`, `construculator_prod`)
2. Add variables to each group: `SENTRY_DSN`, `ENVIRONMENT`, and any other sensitive values
3. Reference the appropriate group in each workflow

**Pre-build Script:**
```sh
# Generate the complete env file from environment group variables
cat > assets/env/.env.$ENVIRONMENT <<EOF
SENTRY_DSN=$SENTRY_DSN
# Add all other environment variables your app requires
# API_BASE_URL=$API_BASE_URL
# API_KEY=$API_KEY
EOF
```

**Build Command:**
```sh
# Use $ENVIRONMENT from the environment group
fvm flutter build apk --flavor fishfood --dart-define=ENVIRONMENT=$ENVIRONMENT
```

This approach keeps sensitive variables organized by environment and generates env files at build time without committing them to source control.

### 3.2 Initialize Sentry in main.dart

Wrap app initialization with `SentryFlutter.init()`:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appBootstrap = await _initializeApp();

  await SentryFlutter.init(
    (options) {
      options.dsn = appBootstrap.envLoader.get('SENTRY_DSN') ?? '';
      options.environment = appBootstrap.config.getEnvironmentName(
        appBootstrap.config.environment,
      );

      // Performance monitoring - disabled for now
      options.tracesSampleRate = 0.0;

      // Other settings
      options.attachScreenshot = false;  // Privacy
      options.enableAutoSessionTracking = true;
      options.captureFailedRequests = true;
    },
    appRunner: () => runApp(
      ModularApp(module: AppModule(appBootstrap), child: const AppWidget()),
    ),
  );
}
```

---

## 4. AppLogger Integration

### 4.1 Update AppLogger

Add Sentry calls to `lib/libraries/logging/app_logger.dart`:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

class AppLogger {
  // ... existing code ...

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.i(_formatMessage(message), error: error, stackTrace: stackTrace);

    // Add breadcrumb to Sentry
    Sentry.addBreadcrumb(Breadcrumb(
      message: _formatMessage(message),
      level: SentryLevel.info,
      category: _tag,
    ));
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.w(_formatMessage(message), error: error, stackTrace: stackTrace);

    Sentry.addBreadcrumb(Breadcrumb(
      message: _formatMessage(message),
      level: SentryLevel.warning,
      category: _tag,
      data: error != null ? {'error': error.toString()} : null,
    ));
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.e(_formatMessage(message), error: error, stackTrace: stackTrace);

    // Send error event to Sentry
    if (error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('logger_tag', _tag);
          scope.setContexts('log', {'message': _formatMessage(message)});
        },
      );
    } else {
      Sentry.captureMessage(
        _formatMessage(message),
        level: SentryLevel.error,
        withScope: (scope) => scope.setTag('logger_tag', _tag),
      );
    }
  }

  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.d(_formatMessage(message), error: error, stackTrace: stackTrace);
    // Debug logs NOT sent to Sentry
  }

  void omg(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.f(_formatMessage(message), error: error, stackTrace: stackTrace);

    // Send fatal error to Sentry
    Sentry.captureException(
      error ?? Exception(message),
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('logger_tag', _tag);
        scope.setTag('severity', 'fatal');
        scope.setContexts('log', {'message': _formatMessage(message)});
      },
    );
  }
}
```

### 4.2 What Gets Sent to Sentry

| Method | Console | Sentry Event | Breadcrumb | Use Case |
|--------|---------|--------------|------------|----------|
| `debug()` | ✅ | ❌ | ❌ | Internal state, dev details |
| `info()` | ✅ | ❌ | ✅ | Operations, context |
| `warning()` | ✅ | ❌ | ✅ | Recoverable issues |
| `error()` | ✅ | ✅ | ❌ | Repository exceptions |
| `omg()` | ✅ | ✅ (fatal) | ❌ | Invariant violations |

**Key points:**
- `info()` and `warning()` create breadcrumbs (appear in error reports, don't consume quota)
- `error()` and `omg()` create actual Sentry events (consume quota)
- `debug()` stays local only
- All Sentry calls are no-ops if DSN is empty

---

## 5. User Context

Set user context after authentication:

```dart
// After login
await Sentry.configureScope((scope) {
  scope.setUser(SentryUser(id: userId));
});

// On logout
await Sentry.configureScope((scope) {
  scope.setUser(null);
});
```

Add this to your authentication flow (Inside a repository during signin, login and logout).

---

## 6. Additional Sentry Features

### 6.1 Navigation Tracking

Track screen navigation automatically using `SentryNavigatorObserver` with `flutter_modular`.

Add the observer in your `AppWidget` where you use `MaterialApp.router`:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final routerDelegate = Modular.routerDelegate;
    routerDelegate.setObservers(  
      [
        SentryNavigatorObserver(),
      ]
    );
    routerDeligate.setNavipapp
    return MaterialApp.router(
      title: 'Construculator',
      routerDeligate: Modula
      routerConfig: Modular.routerConfig
      routerDeligate: routerDeligate,
      // ... rest of your config
    );
  }
}
```

**What this gives you:**
- Breadcrumbs for every screen navigation
- Performance tracking for route transitions
- See which screen a user was on when an error occurred

**Example breadcrumb:**
```
navigation: /home → /estimation/create
navigation: /estimation/create → /estimation/123
ERROR: Failed to save estimation
```

### 6.2 Performance Monitoring

Sentry provides performance monitoring capabilities to track app performance metrics.

**Automatic Metrics:**
Enable in `main.dart` Sentry initialization:
```dart
options.tracesSampleRate = 0.2; // Sample 20% of sessions
options.enableAutoPerformanceTracking = true;
options.enableTimeToFullDisplayTracing = true;
```

This tracks:
- App start time (cold/warm starts)
- Screen load time (TTID/TTFD)
- Route transition duration

**Custom Tracking:**
For critical operations:
```dart
final transaction = Sentry.startTransaction('load_estimations', 'task');
try {
  final span = transaction.startChild('database_fetch');
  final result = await repository.fetchEstimations();
  span.finish(status: SpanStatus.ok());
  transaction.finish(status: SpanStatus.ok());
} catch (e) {
  transaction.finish(status: SpanStatus.internalError());
  rethrow;
}
```

### 6.3 HTTP Request Tracking

Enable automatic tracking of failed HTTP requests:

```dart
options.captureFailedRequests = true;
```

This captures:
- Failed HTTP requests (4xx, 5xx)
- Request URL, method, status code
- Request/response headers (sanitized)

### 6.4 User Feedback

Collect user feedback when errors occur:

```dart
final eventId = await Sentry.captureException(exception);

if (eventId != null) {
  final userFeedback = await showDialog<String?>(
    context: context,
    builder: (_) => UserFeedbackDialog(),
  );

  if (userFeedback != null) {
    await Sentry.captureUserFeedback(SentryFeedback(
      associatedEventId: eventId,
      message: userFeedback,
    ));
  }
}
```

**Use case:** Let users describe what they were doing when an error occurred.

### 6.5 Session Replay

> ⚠️ **Not recommended** - Privacy concerns and quota cost

Sentry can record user sessions (screenshots + interactions):

```dart
options.experimental.replay.sessionSampleRate = 0.1; // 10% of sessions
options.experimental.replay.onErrorSampleRate = 1.0;  // All error sessions
```

**Why we're not using it:**
- Privacy: Captures potentially sensitive information
- Quota: Very expensive (large video files)
- Alternatives: Screenshots on error (`attachScreenshot`) is lighter

### 6.6 Release Tracking

Tag errors with app version:

```dart
options.release = 'construculator@1.2.3+45';
```

**Benefits:**
- See which version introduced bugs
- Track regression between releases
- Measure crash-free rate per version

**TODO:** Automate this from `pubspec.yaml` version.

### 6.7 Custom Tags and Context

Add searchable metadata to errors:

```dart
// Global tags (set once)
await Sentry.configureScope((scope) {
  scope.setTag('feature', 'cost_estimation');
  scope.setTag('team', 'mobile');
});

// Event-specific context
Sentry.captureException(
  error,
  withScope: (scope) {
    scope.setTag('operation', 'create_estimation');
    scope.setContexts('estimation', {
      'project_id': projectId,
      'total_cost': totalCost,
    });
  },
);
```

**Use case:** Filter/search errors in Sentry dashboard by feature, team, operation type.

---

## 7. Practical Usage

### 7.1 No Code Changes Needed

Once `AppLogger` is updated, existing repository code automatically reports to Sentry:

```dart
// This already exists in repositories - no changes needed
_logger.error(
  'PostgreSQL error during $operation: code=${error.code}',
  error,
);
```

### 7.2 BLoC Layer

BLoCs should NOT log errors - they receive `Either<Failure, T>` and emit states.

### 7.3 What You'll See in Sentry

When an error occurs, Sentry shows:
- Exception type and message
- Stack trace
- Breadcrumb trail (all `info()` / `warning()` calls before the error)
- Tags: `logger_tag`, `environment`
- User context (if set)
- Device info, OS, Flutter version

---

## 8. Testing

To test locally, temporarily add DSN to `.env.dev`:

```dotenv
SENTRY_DSN=https://your-test-dsn@sentry.io/project
```

Trigger a test error:

```dart
AppLogger().tag('Test').error(
  'Testing Sentry',
  Exception('Test error'),
  StackTrace.current,
);
```

Verify in Sentry dashboard → Issues.

**Remember to remove DSN before committing.**

---

## 9. Best Practices

### 9.1 Don't Send PII

```dart
// ❌ Bad
_logger.error('Login failed for user@example.com');

// ✅ Good
_logger.error('Login failed for userId: $userId');
```

### 9.2 Include Context

```dart
// ✅ Good - includes operation, params, error details
_logger.error(
  'PostgreSQL error during $operation [projectId=$projectId]: '
  'code=${error.code}, message=${error.message}',
  error,
);
```

### 9.3 Use Breadcrumbs Liberally

`info()` and `warning()` don't cost quota - use them to create a trail:

```dart
_logger.info('User tapped create button');
_logger.info('Validation passed');
_logger.warning('Network slow - retrying');
```

---

## 10. Environment Strategy

**Fishfood (.env.dev):**
```dotenv
SENTRY_DSN=  # Empty - disabled
```
- Avoids noise from local development
- Only enable temporarily for testing Sentry integration

**Dogfood (.env.qa):**
```dotenv
SENTRY_DSN=https://your-qa-dsn@sentry.io/project
```
- Separate Sentry project for QA
- Catch bugs before production

**Production (.env.prod):**
```dotenv
SENTRY_DSN=https://your-prod-dsn@sentry.io/project
```
- Main production monitoring

---

## 11. Summary

**Currently enabled:**
- ✅ Error capture via `AppLogger.error()` / `AppLogger.omg()`
- ✅ Breadcrumbs via `AppLogger.info()` / `AppLogger.warning()`
- ✅ Automatic crash reports
- ✅ Failed HTTP request tracking
- ✅ Session tracking (crash-free rate)

**Available but not enabled (can add later):**
- 📊 Performance monitoring (app start, TTID, TTFD, route transitions)
- 🧭 Navigation tracking via `SentryNavigatorObserver`
- 📝 User feedback collection
- 🏷️ Release tracking (version tagging)
- 🎥 Session replay (not recommended - privacy/cost)

**Integration approach:**
- All error reporting happens through `AppLogger` - no direct Sentry calls in repositories
- Developers don't need to change existing code
- BLoCs don't log errors - only repositories do

---

## 12. Related Documentation

- [Sentry Flutter Documentation](https://docs.sentry.io/platforms/flutter/)
- [Performance Monitoring](https://docs.sentry.io/platforms/flutter/performance/)
- [Breadcrumbs](https://docs.sentry.io/platforms/flutter/enriching-events/breadcrumbs/)
- [User Context](https://docs.sentry.io/platforms/flutter/enriching-events/identify-user/)

---

**Last Updated:** 2026-02-20
**Maintained By:** Engineering Team
**Review Cycle:** After major Sentry SDK updates
