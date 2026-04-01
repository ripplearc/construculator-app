import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class InitialRouteModule extends Module {
  final AppBootstrap appBootstrap;
  InitialRouteModule(this.appBootstrap);

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const InitialRouteHandler());
  }
}

class InitialRouteHandler extends StatefulWidget {
  const InitialRouteHandler({super.key});

  @override
  State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
  @override
  void initState() {
    super.initState();
    _navigateToInitialRoute();
  }

  Future<void> _navigateToInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final authManager = Modular.get<AuthManager>();
    final isAuthenticated = await authManager.isAuthenticated();

    if (!mounted) return;

    if (isAuthenticated) {
      Modular.to.navigate(fullDashboardRoute);
    } else {
      Modular.to.navigate(fullLoginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    return Scaffold(
      backgroundColor: colors.backgroundDarkOrient,
      body: SizedBox.shrink(),
    );
  }
}
