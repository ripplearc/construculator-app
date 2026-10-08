// coverage:ignore-file

/// Error type for [CurrentCompanyResolver] operations.
///
/// - [connectionError]: network connectivity issues
/// - [timeoutError]: the operation timed out
/// - [unexpectedDatabaseError]: the RPC call failed on the database side
/// - [unexpectedError]: anything not covered above
enum CompanyErrorType {
  connectionError,
  timeoutError,
  unexpectedDatabaseError,
  unexpectedError,
}
