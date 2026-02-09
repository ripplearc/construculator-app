import 'package:construculator/app/app.dart';
import 'package:construculator/app/app_module.dart';
import 'package:construculator/libraries/config/app_config_impl.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/env_loader_impl.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/supabase/supabase_wrapper_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appBootstrap = await _initializeApp();
  runApp(ModularApp(
    module: AppModule(appBootstrap),
    child: const AppWidget(),
  ));
}

Future<AppBootstrap> _initializeApp() async {
  final String envName = const String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: devEnv,
  );

  final Environment env = _getEnvironmentFromString(envName);
  final envLoader = EnvLoaderImpl();
  final config = AppConfigImpl(envLoader: envLoader);
  await config.initialize(env);
  final wrapper = SupabaseWrapperImpl(envLoader: envLoader);
  await wrapper.initialize();
  return AppBootstrap(
    config: config,
    envLoader: envLoader,
    supabaseWrapper: wrapper,
  );
}

Environment _getEnvironmentFromString(String? envName) {
  switch (envName?.toLowerCase()) {
    case prodEnv:
      return Environment.prod;
    case qaEnv:
      return Environment.qa;
    case devEnv:
      return Environment.dev;
    default:
      return Environment.dev;
  }
}
