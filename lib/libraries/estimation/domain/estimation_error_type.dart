// coverage:ignore-file

/// Error type for estimation operations.
///
/// - [connectionError]: network connectivity issues
/// - [parsingError]: data parsing or mapping failed
/// - [timeoutError]: the operation timed out
/// - [unexpectedDatabaseError]: database query or operation failed
enum EstimationErrorType {
  connectionError,
  parsingError,
  timeoutError,
  unexpectedDatabaseError,
  unexpectedError,
}
