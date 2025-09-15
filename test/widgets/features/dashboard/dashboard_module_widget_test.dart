import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/testing/fake_app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/libraries/modular/testing/fake_injector.dart';
import 'package:construculator/libraries/router/testing/fake_route_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardModule Widget Tests', () {
    late AppBootstrap fakeBootstrap;
    late DashboardModule module;

    setUp(() {
      fakeBootstrap = FakeAppBootstrap();
      module = DashboardModule(fakeBootstrap);
    });
    group('route registration', () {
      testWidgets('should register dashboard route', (
        WidgetTester tester,
      ) async {
        final fakeRouteManager = FakeRouteManager();

        module.routes(fakeRouteManager);

        expect(fakeRouteManager.addedRoutes.length, 1);
        final dashboardRoute = fakeRouteManager.addedRoutes.first;
        expect(dashboardRoute.name, '/');
      });
    });

    group('dependency injection', () {
      testWidgets('should not register any dependencies', (
        WidgetTester tester,
      ) async {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.executedFactories, 0);
        expect(fakeInjector.useCaseFactories, 0);
        expect(fakeInjector.blocFactories, 0);
      });

      testWidgets('should have zero dependency calls', (
        WidgetTester tester,
      ) async {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.lazySingletonCalls, 0);
        expect(fakeInjector.addCalls, 0);
        expect(fakeInjector.totalCalls, 0);
      });
    });
  });
}
