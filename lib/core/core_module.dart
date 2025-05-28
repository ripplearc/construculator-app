import 'package:construculator_app_architecture/core/libraries/storage/shared_pref_service.dart';
import 'package:construculator_app_architecture/core/libraries/storage/interfaces/storage_service.dart' show IStorageService;
import 'package:flutter_modular/flutter_modular.dart';

class CoreModule extends Module {

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<IStorageService>(() => SharedPrefService());
  }
}
