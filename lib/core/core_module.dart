import 'package:construculator/core/config/app_config.dart';
import 'package:construculator/core/config/interfaces/app_config_interfaces.dart';
import 'package:construculator/core/libraries/logging/interfaces/ilogger.dart';
import 'package:construculator/core/libraries/logging/logger.dart';
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
    
    // Logger: Bind ILogger to an instance of LoggerImpl with a specific tag for AppConfig
    // If other parts of your app need tagged loggers, you might consider a factory binding for ILogger
    // that can create LoggerImpl instances with different tags.
    i.addLazySingleton<ILogger>(() => LoggerImpl("App-Config"));

    // AppConfig itself, with dependencies injected by Modular
    i.addLazySingleton<AppConfig>(() => AppConfig(
      dotEnvLoader: i.get<DotEnvLoader>(), 
      supabaseInitializer: i.get<SupabaseInitializer>(), 
      logger: i.get<ILogger>(),
    ));
  }
}
