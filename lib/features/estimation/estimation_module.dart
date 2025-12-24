import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class RouteDefinition {
  final String route;
  final WidgetBuilder widget;
  final List<RouteGuard> guards;

  RouteDefinition(this.route, this.widget, this.guards);
}

class EstimationModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationModule(this.appBootstrap);

  final List<RouteDefinition> _routeDefinitions = [
    RouteDefinition(
      estimationLandingRoute,
      (context) => CostEstimationLandingPage(),
      [AuthGuard()],
    ),
  ];

  List<RouteDefinition> get routeDefinitions => _routeDefinitions;

  @override
  List<Module> get imports => [AuthModule(appBootstrap)];

  @override
  void routes(RouteManager r) {
    for (final routeDef in _routeDefinitions) {
      r.child(routeDef.route, guards: routeDef.guards, child: routeDef.widget);
    }
  }
}
