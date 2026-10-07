// coverage:ignore-file
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';

/// In-memory [StorageService] for tests, with switches to make reads or
/// writes fail.
class FakeStorageService implements StorageService {
  final Map<String, Object?> _data = {};

  /// When true, [getData] throws.
  bool shouldThrowOnRead = false;

  /// When true, [saveData] throws.
  bool shouldThrowOnWrite = false;

  /// The value stored under [key], or null when nothing is stored.
  Object? valueOf(String key) => _data[key];

  /// Clears stored data and failure switches.
  void reset() {
    _data.clear();
    shouldThrowOnRead = false;
    shouldThrowOnWrite = false;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<T?> getData<T>(String key) async {
    if (shouldThrowOnRead) throw StateError('read failed');
    return _data[key] as T?;
  }

  @override
  Future<void> saveData<T>(String key, T value) async {
    if (shouldThrowOnWrite) throw StateError('write failed');
    _data[key] = value;
  }

  @override
  Future<void> removeData(String key) async => _data.remove(key);

  @override
  Future<void> clearAll() async => _data.clear();
}
