import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/toast/toast_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DashboardModule extends Module {
  @override
  List<Module> get imports => [ToastModule(), RouterModule()];
  @override
  void routes(RouteManager r) {
    r.child(
      dashboardRoute,
      guards: [AuthGuard()],
      child: (context) => const DashboardPage(),
    );
  }
}
