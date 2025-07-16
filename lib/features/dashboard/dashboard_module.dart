import 'package:construculator/app/module_param.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/toast/toast_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DashboardModule extends Module {
  final ModuleParam moduleParam;
  DashboardModule(this.moduleParam);
  @override
  List<Module> get imports => [
    AuthLibraryModule(moduleParam),
    ToastModule(),
    RouterModule(),
  ];
  @override
  void routes(RouteManager r) {
    r.child(
      dashboardRoute,
      guards: [AuthGuard()],
      child: (context) => const DashboardPage(),
    );
  }
}
