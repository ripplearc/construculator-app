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
}
