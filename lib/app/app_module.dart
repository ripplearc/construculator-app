import 'package:construculator/features/auth/auth_module.dart';
// ...existing code...
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/shell_routes.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppModule extends Module {
  final AppBootstrap appBootstrap;
  AppModule(this.appBootstrap);
  @override
  List<Module> get imports => [
    RouterModule(),
    ConfigModule(appBootstrap),
    SupabaseModule(appBootstrap),
    AuthLibraryModule(appBootstrap),
    ProjectModule(appBootstrap),
    // Feature modules are now loaded lazily per tab
  ];
  // No shell binds here; handled by ShellModule

  @override
  void routes(RouteManager r) {
    r.module('/auth', module: AuthModule(appBootstrap));
    r.module('/', module: ShellModule(appBootstrap));
    // Feature modules are loaded lazily per tab
  }
}
