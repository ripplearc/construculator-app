// coverage:ignore-file
import 'package:construculator/libraries/storage/models/device_setting.dart';

/// The device space of the storage library: settings of the phone that hold
/// no user's data and survive any sign-out.
///
/// Only the values of [DeviceSetting] can be stored, so the list a reviewer
/// checks is the enum.
abstract class DeviceSpaceStorageService {
  /// The value saved for [setting], or null when nothing is saved.
  Future<T?> getSetting<T>(DeviceSetting setting);

  /// Saves [value] for [setting].
  ///
  /// Throws an [ArgumentError] when [value] is not a string, int, double,
  /// bool or list of strings, and a [StateError] when the platform refuses the
  /// write.
  Future<void> saveSetting<T>(DeviceSetting setting, T value);

  /// Forgets the value saved for [setting].
  ///
  /// Throws a [StateError] when the platform refuses the removal.
  Future<void> removeSetting(DeviceSetting setting);
}
