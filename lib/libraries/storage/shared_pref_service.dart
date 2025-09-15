import 'package:construculator/libraries/storage/interfaces/storage_service.dart';

class SharedPrefService implements StorageService {
  @override
  Future<void> initialize() async {}
  @override
  Future<T?> getData<T>(String key) {
    // TODO: https://ripplearc.youtrack.cloud/issue/CA-14/Storage-Library-Implementation
    throw UnimplementedError();
  }

  @override
  Future<void> saveData<T>(String key, T value) {
    // TODO: https://ripplearc.youtrack.cloud/issue/CA-14/Storage-Library-Implementation
    throw UnimplementedError();
  }

  @override
  Future<void> clearAll() {
    // TODO: https://ripplearc.youtrack.cloud/issue/CA-14/Storage-Library-Implementation
    throw UnimplementedError();
  }

  @override
  Future<void> removeData(String key) {
    // TODO: https://ripplearc.youtrack.cloud/issue/CA-14/Storage-Library-Implementation
    throw UnimplementedError();
  }
}
