// coverage:ignore-file
import 'package:construculator/libraries/storage/interfaces/device_space_storage_service.dart';
import 'package:construculator/libraries/storage/models/device_setting.dart';

/// In-memory [DeviceSpaceStorageService] for tests, with switches to make a
/// read or a write fail. A value of another type than the one asked for reads
/// as null, like the real service. Unlike the real service it accepts any
/// value, so a test cannot rely on it to refuse an unstorable one.
class FakeDeviceSpaceStorageService implements DeviceSpaceStorageService {
  final Map<DeviceSetting, Object?> _settings = {};

  /// When true, [getSetting] throws.
  bool shouldThrowOnRead = false;

  /// When true, [saveSetting] throws.
  bool shouldThrowOnWrite = false;

  /// The value saved for [setting], or null when nothing is saved.
  Object? valueOf(DeviceSetting setting) => _settings[setting];

  /// Clears the saved settings and the failure switches.
  void reset() {
    _settings.clear();
    shouldThrowOnRead = false;
    shouldThrowOnWrite = false;
  }

  @override
  Future<T?> getSetting<T>(DeviceSetting setting) async {
    if (shouldThrowOnRead) throw StateError('read failed');
    final value = _settings[setting];
    return value is T ? value : null;
  }

  @override
  Future<void> saveSetting<T>(DeviceSetting setting, T value) async {
    if (shouldThrowOnWrite) throw StateError('write failed');
    _settings[setting] = value;
  }

  @override
  Future<void> removeSetting(DeviceSetting setting) async =>
      _settings.remove(setting);
}
