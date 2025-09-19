/// Storage service interface, used to store, retrieve and remove data from the device's storage.
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

  /// Remove all data from the storage service.
  Future<void> clearAll();
}
