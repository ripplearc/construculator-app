// coverage:ignore-file

/// Error type for analytics operations.
///
/// - [timeoutError]: the PostHog capture request timed out
/// - [connectionError]: network connectivity issues reaching PostHog
enum AnalyticsErrorType { timeoutError, connectionError }
