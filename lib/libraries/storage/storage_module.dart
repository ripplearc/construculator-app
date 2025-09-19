import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/shared_pref_service.dart';
import 'package:flutter_modular/flutter_modular.dart';

class StorageModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<StorageService>(() => SharedPrefService());
  }
}
