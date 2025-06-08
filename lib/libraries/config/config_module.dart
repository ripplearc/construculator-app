import 'package:construculator/libraries/config/app_config.dart';
import 'package:construculator/libraries/config/env_loader_impl.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ConfigModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<EnvLoader>(() => EnvLoaderImpl());
    i.addLazySingleton<Config>(() => AppConfigImpl(envLoader: i()));
  }
}
