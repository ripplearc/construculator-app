// coverage:ignore-file

/// Why a calculator store operation failed.
enum CalculatorErrorType {
  /// The entry to update or delete is not in the store: no row has its id,
  /// and it is not one of the defaults.
  notFound,

  /// The local database could not be read or written.
  storageError,

  /// Nobody is signed in, so there is no account to keep the entry for.
  notSignedIn,
}
