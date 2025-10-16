import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/app_module.dart';
import 'package:construculator/app/testing/fake_app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/libraries/router/testing/fake_route_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppBootstrap fakeBootstrap;
  late AppModule module;

  setUp(() {
    fakeBootstrap = FakeAppBootstrap();
    module = AppModule(fakeBootstrap);
  });

  group('AppModule', () {
    test('imports contain required modules', () {
      final imports = module.imports;

      expect(imports, hasLength(4));
    });

    test('routes register correct modules', () {
      final fakeRouteManager = FakeRouteManager();

      module.routes(fakeRouteManager);

      expect(fakeRouteManager.addedRoutes.length, 2);

      final authRoute = fakeRouteManager.addedRoutes.firstWhere(
        (r) => r.name == '/auth',
        orElse: () => throw 'Missing /auth route',
      );
      final dashboardRoute = fakeRouteManager.addedRoutes.firstWhere(
        (r) => r.name == '/',
        orElse: () => throw 'Missing / route',
      );

      expect(authRoute.module, isA<AuthModule>());
      expect(dashboardRoute.module, isA<DashboardModule>());

      expect(
        (authRoute.module as AuthModule).appBootstrap,
        same(fakeBootstrap),
      );
      expect(
        (dashboardRoute.module as DashboardModule).appBootstrap,
        same(fakeBootstrap),
      );
    });
  });
}
