import 'dart:async';

import 'package:construculator/libraries/secure_storage/interfaces/secure_storage_wrapper.dart';
import 'package:flutter/services.dart';

/// In-memory [SecureStorageWrapper] for tests.
class FakeSecureStorageWrapper implements SecureStorageWrapper {
  final Map<String, String> _values = {};

  final List<({bool Function() isMet, Completer<void> completer})> _waiters =
      [];

  /// Makes [read] throw, as when the platform store is unavailable.
  bool shouldThrowOnRead = false;

  /// Makes [write] throw, as when the platform store is unavailable.
  bool shouldThrowOnWrite = false;

  /// Makes [delete] and [deleteAll] throw, as when the platform store is unavailable.
  bool shouldThrowOnDelete = false;

  /// Every key that currently holds a value.
  Iterable<String> get storedKeys => _values.keys;

  /// Puts [value] under [key] without going through [write].
  void seed(String key, String value) => _values[key] = value;

  /// Completes once [key] holds a value; at once if it already does.
  ///
  /// For code that saves in the background, such as Supabase's session saving,
  /// so a test can wait for the save without timing guesses.
  Future<void> untilWritten(String key) =>
      _waitUntil(() => _values.containsKey(key));

  /// Completes once [key] holds no value; at once if it already holds none.
  Future<void> untilRemoved(String key) =>
      _waitUntil(() => !_values.containsKey(key));

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
    _releaseWaiters();
  }

  @override
  Future<void> delete(String key) async {
    if (shouldThrowOnDelete) throw PlatformException(code: 'delete_failed');
    _values.remove(key);
    _releaseWaiters();
  }

  @override
  Future<void> deleteAll() async {
    if (shouldThrowOnDelete) throw PlatformException(code: 'delete_failed');
    _values.clear();
    _releaseWaiters();
  }

  /// Empties the store and makes every operation succeed again.
  void reset() {
    _values.clear();
    _waiters.clear();
    shouldThrowOnRead = false;
    shouldThrowOnWrite = false;
    shouldThrowOnDelete = false;
  }

  Future<void> _waitUntil(bool Function() isMet) {
    if (isMet()) return Future.value();
    final completer = Completer<void>();
    _waiters.add((isMet: isMet, completer: completer));
    return completer.future;
  }

  void _releaseWaiters() {
    _waiters.removeWhere((waiter) {
      if (!waiter.isMet()) return false;
      waiter.completer.complete();
      return true;
    });
  }
}
