import 'package:construculator_app_architecture/app/app.dart';
import 'package:construculator_app_architecture/app/app_module.dart';
import 'package:construculator_app_architecture/core/config/constants.dart';
import 'package:construculator_app_architecture/core/config/app_config.dart';
import 'package:flavor_config/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final String envName = const String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: devEnv,
  );

  final Environment env = _getEnvironmentFromString(envName);

  await AppConfig.instance.initialize(env);

  if (!(!AppConfig.instance.isProd)) {
    FlavorConfig(
      flavorName: AppConfig.instance.getEnvironmentName(env),
      bannerColor: _getEnvironmentColor(env),
      values: {},
    );
  }
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
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

Color _getEnvironmentColor(Environment env) {
  switch (env) {
    case Environment.dev:
      return Colors.green;
    case Environment.qa:
      return Colors.orange;
    case Environment.prod:
      return Colors.red;
  }
}
