import 'package:construculator/libraries/config/app_config.dart';
import 'package:construculator/libraries/config/dotenv_loader.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ConfigModule extends Module {

  @override
  List<Module> get imports => [
    SupabaseModule(),
  ];

  @override
  void binds(Injector i) {
    i.addLazySingleton<EnvLoader>(() => DotEnvLoader());
  }

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<Config>(() => AppConfig(
      dotEnvLoader: i(), 
      supabaseInitializer: i(), 
    ));
  }
}
