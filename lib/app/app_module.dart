import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppModule extends Module {
  final AppBootstrap appBootstrap;
  AppModule(this.appBootstrap);
  @override
  List<Module> get imports => [
    ConfigModule(appBootstrap),
    SupabaseModule(appBootstrap),
    AuthLibraryModule(appBootstrap),
  ];
  @override
  void routes(RouteManager r) {
    r.module('/auth', module: AuthModule(appBootstrap));
    r.module('/', module: DashboardModule(appBootstrap));
    r.module('/estimation', module: EstimationModule(appBootstrap));
  }
}
