// coverage:ignore-file
/// Reads and writes small secrets in the platform's encrypted store: the
/// iOS Keychain and the Android Keystore.
///
/// Wraps the flutter_secure_storage plugin so no other code imports it.
/// Tests swap in `FakeSecureStorageWrapper`.
abstract class SecureStorageWrapper {
  /// Returns the value stored under [key], or null when there is none.
  ///
  /// On Android, a value that cannot be decrypted (for example after a
  /// restore) is deleted and this returns null. Throws for other platform
  /// errors.
  Future<String?> read(String key);

  /// Stores [value] under [key], replacing any earlier value.
  ///
  /// Throws when the platform store cannot be written.
  Future<void> write(String key, String value);

  /// Removes the value stored under [key]. Does nothing when there is none.
  ///
  /// Throws when the platform store cannot be written.
  Future<void> delete(String key);
}
