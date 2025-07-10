import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// This class is used to pass parameters to the app module.
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