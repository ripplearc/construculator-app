// coverage:ignore-file

/// Error types for global search operations.
///
/// - [connectionError]: network connectivity issue prevented the operation
/// - [parsingError]: data parsing or mapping from the response failed
/// - [timeoutError]: the operation timed out before completing
/// - [unexpectedDatabaseError]: a database query or operation failed unexpectedly
/// - [notFoundError]: the requested record was not found
/// - [duplicateEntryError]: a unique constraint was violated (e.g. concurrent upsert)
enum SearchErrorType {
  connectionError,
  parsingError,
  timeoutError,
  unexpectedDatabaseError,
  notFoundError,
  duplicateEntryError,
}
