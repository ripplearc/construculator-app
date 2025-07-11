// coverage:ignore-file
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// This is the implementation of the app router using Modular.
class ModularRouterImpl implements AppRouter {
  @override
  Future<void> pushNamed(String route, {Object? arguments}) {
    return Modular.to.pushNamed(route, arguments: arguments);
  }

  @override
  void navigate(String route, {Object? arguments}) {
    Modular.to.pushNamedAndRemoveUntil(
      route,
      (_) => false,
      arguments: arguments,
    );
  }

  @override
  void pop<T extends Object?>([T? result]) {
    Modular.to.pop();
  }
}
