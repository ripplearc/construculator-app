import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class _RouteDefinition {
  final String route;
  final WidgetBuilder widget;
  final List<RouteGuard> guards;

  _RouteDefinition(this.route, this.widget, this.guards);
}

class EstimationModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationModule(this.appBootstrap);

  final List<_RouteDefinition> _routeDefinitions = [
    _RouteDefinition(estimationLandingRoute, (context) => Container(), [
      AuthGuard(),
    ]),
  ];

  List<_RouteDefinition> get routeDefinitions => _routeDefinitions;

  @override
  List<Module> get imports => [AuthLibraryModule(appBootstrap), RouterModule()];

  @override
  void routes(RouteManager r) {
    for (final routeDef in _routeDefinitions) {
      r.child(routeDef.route, guards: routeDef.guards, child: routeDef.widget);
    }
  }
}
