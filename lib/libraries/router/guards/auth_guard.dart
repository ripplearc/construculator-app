import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';

/// Guard that ensures the user is authenticated before allowing access to a route.
/// Use this guard on routes that requires that the user is authenticated.
class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: fullLoginRoute);

  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
    return Modular.get<AuthManager>().isAuthenticated();
  }
}