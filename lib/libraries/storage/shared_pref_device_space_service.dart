import 'package:construculator/libraries/storage/interfaces/device_space_storage_service.dart';
import 'package:construculator/libraries/storage/models/device_setting.dart';
import 'package:construculator/libraries/storage/prefixed_preferences.dart';

/// [DeviceSpaceStorageService] over the platform preferences.
///
/// Keys are stored under `device.`, a prefix the user space never clears.
class SharedPrefDeviceSpaceService implements DeviceSpaceStorageService {
  /// The text put in front of every key of the device space.
  static const keyPrefix = 'device.';

  final PrefixedPreferences _preferences;

  /// A device space over [preferences], which must use [keyPrefix].
  SharedPrefDeviceSpaceService({required this._preferences});

  @override
  Future<T?> getSetting<T>(DeviceSetting setting) =>
      _preferences.get<T>(setting.name);

  @override
  Future<void> saveSetting<T>(DeviceSetting setting, T value) =>
      _preferences.save<T>(setting.name, value);

  @override
  Future<void> removeSetting(DeviceSetting setting) =>
      _preferences.remove(setting.name);
}
