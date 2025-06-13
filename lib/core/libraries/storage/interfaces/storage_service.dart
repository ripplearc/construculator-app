/// Storage service interface, used to store and retrieve data from the device's storage.
/// This is a singleton class, so it can be accessed from anywhere in the app.
abstract class IStorageService {
  /// Initialize the storage service, Some storage services may need to be initialized before use.
  Future<void> initialize();

  /// Save data to the storage service.
  Future<void> saveData<T>(String key, T value);

  /// Get data from the storage service.
  Future<T?> getData<T>(String key);

  /// Remove data from the storage service.
  Future<void> removeData(String key);

  /// Clear all data from the storage service.
  Future<void> clearAll();
  
}