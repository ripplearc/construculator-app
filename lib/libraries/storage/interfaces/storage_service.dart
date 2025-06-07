/// Storage service interface, used to store, retrieve and remove data from the device's storage.
/// 
/// [initialize] is used to initialize the storage service, Some storage services may need to be initialized before use.
/// [saveData] is used to save data to the storage service.
/// [getData] is used to get data from the storage service.
/// [removeData] is used to remove data from the storage service.
/// [clearAll] is used to clear all data from the storage service.
abstract class StorageService {
  Future<void> initialize();
  Future<void> saveData<T>(String key, T value);
  Future<T?> getData<T>(String key);
  Future<void> removeData(String key);
  Future<void> clearAll();
}