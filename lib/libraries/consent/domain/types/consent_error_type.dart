// coverage:ignore-file

/// Error type for consent operations.
///
/// Only the write path and genuinely unexpected conditions surface as errors.
/// A failed *read* or a failed *version check* is not represented here — those
/// resolve to a `ConsentStatus` instead, because "we could not check" is a
/// state the gate has to reason about, not a failure to report.
///
/// - [connectionError]: network connectivity issues
/// - [parsingError]: a consent row could not be mapped
/// - [timeoutError]: the operation timed out
/// - [unexpectedDatabaseError]: local or remote query failed
/// - [permissionDenied]: the row was rejected, typically by RLS
/// - [authenticationError]: no signed-in user to attribute the record to
/// - [unexpectedError]: anything not covered above
enum ConsentErrorType {
  connectionError,
  parsingError,
  timeoutError,
  unexpectedDatabaseError,
  permissionDenied,
  authenticationError,
  unexpectedError,
}
