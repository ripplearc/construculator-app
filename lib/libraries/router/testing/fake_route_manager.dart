import 'package:flutter_modular/flutter_modular.dart';

/// A fake RouteManager for testing that captures added routes.
class FakeRouteManager implements RouteManager {
  final List<ModularRoute> addedRoutes = [];

  @override
  void add(ModularRoute route) {
    addedRoutes.add(route);
  }

  /// Clears the captured routes for a clean state between tests.
  void reset() {
    addedRoutes.clear();
  }

  // We don't need other methods for this test, so just throw if they're called.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
