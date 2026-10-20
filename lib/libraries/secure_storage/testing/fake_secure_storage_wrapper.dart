import 'package:construculator/libraries/secure_storage/interfaces/secure_storage_wrapper.dart';
import 'package:flutter/services.dart';

/// In-memory [SecureStorageWrapper] for tests.
class FakeSecureStorageWrapper implements SecureStorageWrapper {
  final Map<String, String> _values = {};

  /// Makes [read] throw, as when the platform store is unavailable.
  bool shouldThrowOnRead = false;

  /// Makes [write] throw, as when the platform store is unavailable.
  bool shouldThrowOnWrite = false;

  /// Makes [delete] throw, as when the platform store is unavailable.
  bool shouldThrowOnDelete = false;

  /// Every key that currently holds a value.
  Iterable<String> get storedKeys => _values.keys;

  /// Puts [value] under [key] without going through [write].
  void seed(String key, String value) => _values[key] = value;

  /// Returns the value under [key] without going through [read].
  String? peek(String key) => _values[key];

  @override
  Future<String?> read(String key) async {
    if (shouldThrowOnRead) throw PlatformException(code: 'read_failed');
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (shouldThrowOnWrite) throw PlatformException(code: 'write_failed');
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (shouldThrowOnDelete) throw PlatformException(code: 'delete_failed');
    _values.remove(key);
  }

  /// Empties the store and makes every operation succeed again.
  void reset() {
    _values.clear();
    shouldThrowOnRead = false;
    shouldThrowOnWrite = false;
    shouldThrowOnDelete = false;
  }
}
