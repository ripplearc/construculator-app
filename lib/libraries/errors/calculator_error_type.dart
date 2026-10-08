// coverage:ignore-file

/// Why a calculator store operation failed.
enum CalculatorErrorType {
  /// The row to update or delete is not in the store.
  notFound,

  /// The local database could not be read or written.
  storageError,
}
