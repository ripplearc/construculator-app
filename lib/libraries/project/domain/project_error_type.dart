// coverage:ignore-file

/// Error type for project operations.
///
/// - [connectionError]: network connectivity issues
/// - [parsingError]: data parsing or mapping failed
/// - [timeoutError]: the operation timed out
/// - [unexpectedDatabaseError]: database query or operation failed
/// - [unexpectedError]: an unclassified error occurred
/// - [notFoundError]: the requested project does not exist
/// - [permissionDenied]: user lacks required permission for the operation
enum ProjectErrorType {
  connectionError,
  parsingError,
  timeoutError,
  unexpectedDatabaseError,
  unexpectedError,
  notFoundError,
  permissionDenied,
}
