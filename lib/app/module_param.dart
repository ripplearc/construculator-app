import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// The app module requires that the supabase client is initialized before the app module starts, this is for the purposes of route guard checks.
/// This can not be done in the constructor of the app module, and modules do not have any special init functions for this purpose.
/// Supabase client depends on [Config] and [EnvLoader] for initialization.
/// Both [Config] and [EnvLoader] are passed to the app module as parameters to ensure the same instance used for the supabase client 
/// is registered and used across the app.
/// Example usage:
/// ```dart
/// final Environment env = _getEnvironmentFromString(envName);
/// final envLoader = EnvLoaderImpl();
/// final config = AppConfigImpl(envLoader: envLoader);
/// await config.initialize(env);
/// final wrapper = SupabaseWrapperImpl(envLoader: envLoader);
/// await wrapper.initialize();
/// final params = ModuleParam(config: config, envLoader: envLoader, supabaseWrapper: wrapper);
/// runApp(ModularApp(module: AppModule(params), child: const AppWidget()));
class ModuleParam {
  /// The environment loader, required by [Config] for initialization.
  final EnvLoader envLoader;

  /// The app config, required by supabase wrapper for initialization.
  final Config config;

  /// The supabase wrapper, has to be instantiated before passing to the app module.
  final SupabaseWrapper supabaseWrapper;

  ModuleParam({
    required this.envLoader,
    required this.config,
    required this.supabaseWrapper,
  });
}