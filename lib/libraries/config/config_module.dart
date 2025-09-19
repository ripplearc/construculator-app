import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ConfigModule extends Module {
  final AppBootstrap appBootstrap;
  ConfigModule(this.appBootstrap);
  @override
  void exportedBinds(Injector i) {
    i.addSingleton<EnvLoader>(() => appBootstrap.envLoader);
    i.addSingleton<Config>(() => appBootstrap.config);
  }
}
