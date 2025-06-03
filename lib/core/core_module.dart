import 'package:construculator/core/config/app_config.dart';
import 'package:construculator/core/config/interfaces/app_config_interfaces.dart';
import 'package:construculator/core/libraries/logging/interfaces/logger.dart';
import 'package:construculator/core/libraries/logging/construculator_logger.dart';
import 'package:construculator/core/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/core/libraries/storage/shared_pref_service.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CoreModule extends Module {

  @override
  void exportedBinds(Injector i) {
    // Storage Service
    i.addLazySingleton<StorageService>(() => SharedPrefServiceImpl());

    // AppConfig Dependencies
    i.addLazySingleton<DotEnvLoader>(() => DotEnvLoaderImpl());
    i.addLazySingleton<SupabaseInitializer>(() => SupabaseInitializerImpl());
    
    // Logger: Bind AppLogger to an instance of ConstruculatorLogger.
    // The default tag for the initially injected logger will be "App".
    // Specific tags can be applied by calling .tag() on the injected instance.
    i.addLazySingleton<AppLogger>(() => ConstruculatorLogger(initialTag: "App"));

    // AppConfig itself, with dependencies injected by Modular
    i.addLazySingleton<AppConfig>(() => AppConfig(
      dotEnvLoader: i.get<DotEnvLoader>(), 
      supabaseInitializer: i.get<SupabaseInitializer>(), 
      logger: i.get<AppLogger>(), 
    ));
  }
}
