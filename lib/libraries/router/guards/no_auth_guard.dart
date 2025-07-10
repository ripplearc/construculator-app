import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Guard that ensures the user is not authenticated before allowing access to a route.
/// Use this guard on routes that requires that the user is not authenticated.
class NoAuthGuard extends RouteGuard {
  NoAuthGuard() : super(redirectTo: dashboardRoute);

  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
   return !Modular.get<AuthManager>().isAuthenticated();
  }
}