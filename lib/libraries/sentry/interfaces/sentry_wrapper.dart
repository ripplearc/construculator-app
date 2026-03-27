/// Sealed enum for Sentry event levels
/// This provides type-safe log levels and prevents invalid states
sealed class SentryEventLevel {
  const SentryEventLevel();
}

/// Debug level - detailed information for diagnosing issues
class SentryDebugLevel extends SentryEventLevel {
  const SentryDebugLevel();
}

/// Info level - general informational messages
class SentryInfoLevel extends SentryEventLevel {
  const SentryInfoLevel();
}

/// Warning level - potentially harmful situations
class SentryWarningLevel extends SentryEventLevel {
  const SentryWarningLevel();
}

/// Error level - error events that might still allow the app to continue
class SentryErrorLevel extends SentryEventLevel {
  const SentryErrorLevel();
}

/// Fatal level - severe error events that will presumably lead the app to abort
class SentryFatalLevel extends SentryEventLevel {
  const SentryFatalLevel();
}

/// Interface that wraps Sentry functionality
/// This allows for easier testing by providing a clean abstraction layer
abstract class SentryWrapper {
  /// Initialize Sentry with the provided app runner
  ///
  /// This method configures Sentry with DSN from environment variables
  /// and wraps the app runner to capture errors automatically.
  ///
  /// If SENTRY_DSN is not set or empty, the app will run without Sentry
  /// initialization to prevent silent no-op scenarios.
  ///
  /// [appRunner] The function that runs the Flutter app
  Future<void> initialize(void Function() appRunner);

  /// Add a breadcrumb to track user actions leading up to an error
  ///
  /// [message] The breadcrumb message
  /// [level] The severity level
  /// [category] Optional category for grouping breadcrumbs
  /// [data] Optional additional data
  Future<void> addBreadcrumb({
    required String message,
    required SentryEventLevel level,
    String? category,
    Map<String, dynamic>? data,
  });

  /// Capture an exception with optional stack trace
  ///
  /// [exception] The exception to capture
  /// [stackTrace] Optional stack trace
  /// [tags] Optional tags for categorization
  /// [contexts] Optional additional context data
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    Map<String, String>? tags,
    Map<String, dynamic>? contexts,
  });

  /// Capture a message with a specified level
  ///
  /// [message] The message to capture
  /// [level] The severity level
  /// [tags] Optional tags for categorization
  Future<void> captureMessage(
    String message, {
    required SentryEventLevel level,
    Map<String, String>? tags,
  });
}
