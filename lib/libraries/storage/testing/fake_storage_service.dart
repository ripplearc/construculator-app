// coverage:ignore-file
import 'dart:async';

import 'package:construculator/libraries/storage/interfaces/storage_service.dart';

/// In-memory [StorageService] for tests, with switches to make reads, writes,
/// removes or the clear fail, and a way to hold one write until the test
/// releases it. A value of another type than the one asked for reads as
/// null, like the real service. Unlike the real service it accepts any value,
/// so a test cannot rely on it to refuse an unstorable one.
class FakeStorageService implements StorageService {
  final Map<String, Object?> _data = {};
  Completer<void>? _heldWrite;
  Completer<void> _heldWriteStarted = Completer<void>();

  /// When true, [getData] throws.
  bool shouldThrowOnRead = false;

  /// When true, [saveData] throws.
  bool shouldThrowOnWrite = false;

  /// When true, [removeData] throws.
  bool shouldThrowOnRemove = false;

  /// When true, [clearAll] throws.
  bool shouldThrowOnClear = false;

  /// Completes when the write held by [holdNextWrite] starts.
  Future<void> get heldWriteStarted => _heldWriteStarted.future;

  /// Holds the next [saveData] until the returned completer completes, so a
  /// test can order writes without waiting on time.
  Completer<void> holdNextWrite() {
    _heldWriteStarted = Completer<void>();
    return _heldWrite = Completer<void>();
  }

  /// The value stored under [key], or null when nothing is stored.
  Object? valueOf(String key) => _data[key];

  /// Clears stored data, failure switches and a held write.
  void reset() {
    _data.clear();
    _heldWrite = null;
    shouldThrowOnRead = false;
    shouldThrowOnWrite = false;
    shouldThrowOnRemove = false;
    shouldThrowOnClear = false;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<T?> getData<T>(String key) async {
    if (shouldThrowOnRead) throw StateError('read failed');
    final value = _data[key];
    return value is T ? value : null;
  }

  @override
  Future<void> saveData<T>(String key, T value) async {
    final held = _heldWrite;
    _heldWrite = null;
    if (held != null) {
      _heldWriteStarted.complete();
      await held.future;
    }
    if (shouldThrowOnWrite) throw StateError('write failed');
    _data[key] = value;
  }

  @override
  Future<void> removeData(String key) async {
    if (shouldThrowOnRemove) throw StateError('remove failed');
    _data.remove(key);
  }

  @override
  Future<void> clearAll() async {
    if (shouldThrowOnClear) throw StateError('clear failed');
    _data.clear();
  }
}
