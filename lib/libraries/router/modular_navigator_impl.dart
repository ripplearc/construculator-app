// coverage:ignore-file
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Implementation of the [AppRouter] using Modular.
class ModularRouterImpl implements AppRouter {
  @override
  Future<void> pushNamed(String route, {Object? arguments}) {
    return Modular.to.pushNamed(route, arguments: arguments);
  }

  @override
  void navigate(String route, {Object? arguments}) {
    Modular.to.navigate(route, arguments: arguments);
  }

  @override
  void pop() {
    Modular.to.pop();
  }
}
