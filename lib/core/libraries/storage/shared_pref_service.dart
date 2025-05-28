import 'package:construculator_app_architecture/core/libraries/storage/interfaces/storage_service.dart' show IStorageService;

class SharedPrefService implements IStorageService {
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
}
