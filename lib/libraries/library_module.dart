import 'package:construculator/libraries/config/app_config.dart';
import 'package:construculator/libraries/config/dotenv_loader.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/logging/app_logger_wrapper.dart';
import 'package:construculator/libraries/logging/interfaces/logger.dart';
import 'package:construculator/libraries/logging/interfaces/logger_wrapper.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/shared_pref_service.dart';
import 'package:construculator/libraries/supabase/default_supabase_initializer.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_initializer.dart';
import 'package:flutter_modular/flutter_modular.dart';

class LibraryModule extends Module {

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<LoggerWrapper>(() => AppLoggerWrapperImpl());
    i.addLazySingleton<Logger>(() => AppLoggerImpl(internalLogger: i()));
    i.addLazySingleton<StorageService>(() => SharedPrefServiceImpl());
    i.addLazySingleton<EnvLoader>(() => DotEnvLoaderImpl());
    i.addLazySingleton<SupabaseInitializer>(() => DefaultSupabaseInitializerImpl());

    i.addLazySingleton<AppConfig>(() => AppConfig(
      dotEnvLoader: i(), 
      supabaseInitializer: i(), 
      logger: i(), 
    ));
  }
}
