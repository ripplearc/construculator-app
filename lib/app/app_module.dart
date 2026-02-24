import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/calculations/calculations_module.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/members/members_module.dart';
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
    EstimationModule(appBootstrap),
  ];
  @override
  void routes(RouteManager r) {
    r.module('/auth', module: AuthModule(appBootstrap));
    r.child('/', guards: [AuthGuard()], child: (_) => const AppShellPage());
    r.child(
      shellRoute,
      guards: [AuthGuard()],
      child: (_) => const AppShellPage(),
    );

    r.module('/dashboard', module: DashboardModule(appBootstrap));
    r.module('/calculations', module: CalculationsModule(appBootstrap));
    r.module('/members', module: MembersModule(appBootstrap));
    r.module('/estimation', module: EstimationModule(appBootstrap));
  }
}
