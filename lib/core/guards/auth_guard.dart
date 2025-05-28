import 'package:construculator_app_architecture/core/libraries/auth/interfaces/auth_service.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: '/register');

  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
    return Modular.get<IAuthService>().isAuthenticated();
  }
}