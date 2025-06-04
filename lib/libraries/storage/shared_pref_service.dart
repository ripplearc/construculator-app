
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';

class SharedPrefServiceImpl implements StorageService {
  @override
  Future<void> initialize() async {
  }
  @override
  Future<T?> getData<T>(String key) {
    // TODO: implement getData
    throw UnimplementedError();
  }
  
  @override
  Future<void> saveData<T>(String key, T value) {
    // TODO: implement saveData
    throw UnimplementedError();
  }
  
  @override
  Future<void> clearAll() {
    // TODO: implement clearAll
    throw UnimplementedError();
  }
  
  @override
  Future<void> removeData(String key) {
    // TODO: implement removeData
    throw UnimplementedError();
  }
}
