import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/testing/fake_app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/libraries/modular/testing/fake_injector.dart';
import 'package:construculator/libraries/router/testing/fake_route_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppBootstrap fakeBootstrap;
  late AuthModule module;

  setUp(() {
    fakeBootstrap = FakeAppBootstrap();
    module = AuthModule(fakeBootstrap);
  });

  group('AuthModule Widget Tests', () {
    group('route registration', () {
      testWidgets('should register all routes', (WidgetTester tester) async {
        final fakeRouteManager = FakeRouteManager();

        module.routes(fakeRouteManager);

        expect(fakeRouteManager.addedRoutes.length, 6);
      });
    });

    group('dependency injection', () {
      testWidgets('should execute use case factory functions', (
        WidgetTester tester,
      ) async {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.executedFactories, greaterThan(0));
        expect(fakeInjector.useCaseFactories, greaterThan(0));
        expect(fakeInjector.blocFactories, greaterThan(0));
      });

      testWidgets('should register all dependencies with correct counts', (
        WidgetTester tester,
      ) async {
        final fakeInjector = FakeInjector();

        module.binds(fakeInjector);

        expect(fakeInjector.lazySingletonCalls, 8);
        expect(fakeInjector.addCalls, 7);
        expect(fakeInjector.totalCalls, 15);
      });
    });
  });
}
