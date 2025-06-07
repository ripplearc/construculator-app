import 'package:construculator/libraries/config/app_config.dart';
import 'package:construculator/libraries/config/default_supabase_initializer.dart';
import 'package:construculator/libraries/config/dotenv_loader.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_initializer.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ConfigModule extends Module {

  @override
  void binds(Injector i) {
    i.addLazySingleton<SupabaseInitializer>(() => DefaultSupabaseInitializer());
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
