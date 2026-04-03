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
  late final AuthManager _authManager = Modular.get<AuthManager>();

  @override
  void initState() {
    super.initState();
    _navigateToInitialRoute();
  }

  Future<void> _navigateToInitialRoute() async {
    // Allow one frame before navigation dispatch to avoid route handoff races
    // between module initialization and the first rendered frame.
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final isAuthenticated = _authManager.isAuthenticated();

    if (!mounted) return;

    Modular.to.navigate(resolveInitialRoute(isAuthenticated));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    return Scaffold(
      backgroundColor: colors.backgroundDarkOrient,
      body: const SizedBox.shrink(),
    );
  }
}

String resolveInitialRoute(bool isAuthenticated) {
  return isAuthenticated ? fullDashboardRoute : fullLoginRoute;
}
