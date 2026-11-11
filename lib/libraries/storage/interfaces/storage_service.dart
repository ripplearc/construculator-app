/// The user space of the storage library: preferences that belong to the
/// signed-in user.
///
/// The library knows no feature. A feature keeps its keys in one named group of
/// its own, such as `last_used_unit.`. The user space is deleted when the user
/// changes or logs out; a setting that holds no user data goes to
/// `DeviceSpaceStorageService` instead.
abstract class StorageService {
  /// Initialize the storage service, Some storage services may need to be initialized before use.
  Future<void> initialize();

  /// Save data to the storage service.
  ///
  /// [key] is the key of the data to save.
  ///
  /// [value] is the value of the data to save.
  Future<void> saveData<T>(String key, T value);

  /// Get data from the storage service.
  ///
  /// [key] is the key of the data to get.
  Future<T?> getData<T>(String key);

  /// Remove data from the storage service.
  ///
  /// [key] is the key of the data to remove.
  Future<void> removeData(String key);

  /// Remove all data of the user space, and nothing of the device space.
  Future<void> clearAll();
}
