// coverage:ignore-file

/// Error type for feature flag operations.
///
/// - [timeoutError]: the PostHog flag read/reload request timed out
/// - [connectionError]: network connectivity issues reaching PostHog
enum FeatureFlagErrorType { timeoutError, connectionError }
