import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/prefixed_preferences.dart';

/// [StorageService] over the platform preferences.
///
/// Keys are stored under `user.`, so [clearAll] removes this space and leaves
/// the device space and other libraries' keys alone.
class SharedPrefService implements StorageService {
  /// The text put in front of every key of the user space.
  static const keyPrefix = 'user.';

  final PrefixedPreferences _preferences;

  /// A user space over [preferences], which must use [keyPrefix].
  SharedPrefService({required this._preferences});

  @override
  Future<void> initialize() async {}

  @override
  Future<T?> getData<T>(String key) => _preferences.get<T>(key);

  @override
  Future<void> saveData<T>(String key, T value) =>
      _preferences.save<T>(key, value);

  @override
  Future<void> removeData(String key) => _preferences.remove(key);

  @override
  Future<void> clearAll() => _preferences.clear();
}
