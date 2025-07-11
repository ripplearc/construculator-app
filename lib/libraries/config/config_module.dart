import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/app/module_param.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ConfigModule extends Module {
  final ModuleParam moduleParam;
  ConfigModule(this.moduleParam);
  @override
  void exportedBinds(Injector i) {
    i.addSingleton<EnvLoader>(() => moduleParam.envLoader);
    i.addSingleton<Config>(() => moduleParam.config);
  }
}