// coverage:ignore-file

/// Error type for estimation operations.
///
/// - [connectionError]: network connectivity issues
/// - [parsingError]: data parsing or mapping failed
/// - [timeoutError]: the operation timed out
/// - [unexpectedDatabaseError]: database query or operation failed
/// - [authenticationError]: user authentication failed or user not found
/// - [permissionDenied]: user lacks required permission for the operation
/// - [duplicateEntry]: a write was rejected because it collides with an
///   existing record in a way the caller must resolve explicitly (e.g. an
///   unlabeled "Your rates" save into an already-populated name grouping —
///   see `YourRatesRepository.save`), rather than an error the operation can
///   retry or recover from on its own
enum EstimationErrorType {
  connectionError,
  parsingError,
  timeoutError,
  unexpectedDatabaseError,
  unexpectedError,
  authenticationError,
  notFoundError,
  permissionDenied,
  duplicateEntry,
}
