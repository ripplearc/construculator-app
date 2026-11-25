/// Marks an exception for a temporary failure that is expected in normal
/// operation, such as a locked keychain or a storage read that failed once.
///
/// Whoever catches it logs a warning, not an error, because the layer that
/// owns the storage has already reported the cause.
abstract interface class ExpectedException implements Exception {}
