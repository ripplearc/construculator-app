import 'package:construculator_app_architecture/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.instance.appName,
      themeMode: ThemeMode.system,
      routerConfig: Modular.routerConfig,
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: AppConfig.instance.isDev,
    );
  }
}
