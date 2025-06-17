import 'package:construculator/libraries/config/app_config_impl.dart';
import 'package:construculator/libraries/config/env_loader_impl.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
<<<<<<< HEAD
import 'package:flutter_modular/flutter_modular.dart';

class ConfigModule extends Module {
=======
import 'package:construculator/libraries/config/interfaces/supabase_initializer.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ConfigModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<SupabaseInitializer>(() => DefaultSupabaseInitializer());
    i.addLazySingleton<EnvLoader>(() => DotEnvLoader());
  }

>>>>>>> fa844ef (Fix restack conflicts)
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<EnvLoader>(() => EnvLoaderImpl());
    i.addLazySingleton<Config>(() => AppConfigImpl(envLoader: i()));
  }
}
