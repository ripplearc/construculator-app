// coverage:ignore-file
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';

/// In-memory [StorageService] for tests, with switches to make reads, writes
/// or the clear fail. A value of another type than the one asked for reads as
/// null, like the real service.
class FakeStorageService implements StorageService {
  final Map<String, Object?> _data = {};

  /// When true, [getData] throws.
  bool shouldThrowOnRead = false;

  /// When true, [saveData] throws.
  bool shouldThrowOnWrite = false;

  /// When true, [clearAll] throws.
  bool shouldThrowOnClear = false;

  /// The value stored under [key], or null when nothing is stored.
  Object? valueOf(String key) => _data[key];

  /// Clears stored data and failure switches.
  void reset() {
    _data.clear();
    shouldThrowOnRead = false;
    shouldThrowOnWrite = false;
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
    if (shouldThrowOnWrite) throw StateError('write failed');
    _data[key] = value;
  }

  @override
  Future<void> removeData(String key) async => _data.remove(key);

  @override
  Future<void> clearAll() async {
    if (shouldThrowOnClear) throw StateError('clear failed');
    _data.clear();
  }
}
