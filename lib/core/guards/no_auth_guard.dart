import 'package:flutter_modular/flutter_modular.dart';

class NoAuthGuard extends RouteGuard {
  NoAuthGuard() : super(redirectTo: '/');

  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
   return true;
  }
}