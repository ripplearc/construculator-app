abstract class IStorageService {
  Future<void> initialize();
  Future<void> saveData<T>(String key, T value);
  Future<T?> getData<T>(String key);
}