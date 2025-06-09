import 'package:flutter_modular/flutter_modular.dart';

/// Guard that ensures the user is not authenticated before allowing access to a route.
/// Use this guard on routes that requires that the user is not authenticated.
class NoAuthGuard extends RouteGuard {
  NoAuthGuard() : super(redirectTo: '/');

  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
   return true;
  }
}