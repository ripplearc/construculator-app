import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ConfigTestModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<EnvLoader>(() => FakeEnvLoader());
  }
}
