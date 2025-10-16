import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/testing/fake_app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/libraries/modular/testing/fake_injector.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/router/testing/fake_route_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppBootstrap fakeBootstrap;
  late DashboardModule module;

  setUp(() {
    fakeBootstrap = FakeAppBootstrap();
    module = DashboardModule(fakeBootstrap);
  });

  group('DashboardModule', () {
    test('makes dashboard accessible for navigation', () {
      final routeManager = FakeRouteManager();

      module.routes(routeManager);

      final hasDashboardRoute = routeManager.addedRoutes.any(
        (route) => route.name == dashboardRoute,
      );
      expect(
        hasDashboardRoute,
        isTrue,
        reason: 'Dashboard should be accessible via navigation',
      );
    });

    test('is self-contained without external dependencies', () {
      final injector = FakeInjector();

      module.binds(injector);

      expect(
        injector.totalDependencies,
        isZero,
        reason:
            'Dashboard module should work without requiring external dependencies',
      );
    });
  });
}
