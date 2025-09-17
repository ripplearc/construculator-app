import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/presentation/pages/landing_screen.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

class EstimationModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationModule(this.appBootstrap);
  @override
  List<Module> get imports => [AuthLibraryModule(appBootstrap), RouterModule()];
  @override
  void routes(RouteManager r) {
    r.child(
      estimationLandingRoute,
      guards: [AuthGuard()],
      child: (context) => const EstimationLandingPage(),
    );
  }
}
