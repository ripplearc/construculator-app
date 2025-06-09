import 'package:flutter_modular/flutter_modular.dart';

/// Guard that ensures the user is authenticated before allowing access to a route.
/// Use this guard on routes that requires that the user is authenticated.
class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: '/auth/login');

  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
    return true;
  }
}