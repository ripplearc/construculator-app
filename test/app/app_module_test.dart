import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/app_module.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake RouteManager that just stores routes that are added.
class FakeRouteManager implements RouteManager {
  final List<ModularRoute> addedRoutes = [];

  @override
  void add(ModularRoute route) {
    addedRoutes.add(route);
  }

  // We don't need other methods for this test, so just throw if they're called.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAppBootstrap extends Fake implements AppBootstrap {}

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
      expect(imports.any((m) => m is RouterModule), isTrue);
      expect(imports.any((m) => m is ConfigModule), isTrue);
      expect(imports.any((m) => m is SupabaseModule), isTrue);
      expect(imports.any((m) => m is AuthLibraryModule), isTrue);
    });

    test('routes register correct modules', () {
      final fakeRouteManager = FakeRouteManager();

      module.routes(fakeRouteManager);

      expect(fakeRouteManager.addedRoutes.length, 2);

      final authRoute = fakeRouteManager.addedRoutes
          .firstWhere((r) => r.name == '/auth', orElse: () => throw 'Missing /auth route');
      final dashboardRoute = fakeRouteManager.addedRoutes
          .firstWhere((r) => r.name == '/', orElse: () => throw 'Missing / route');

      expect(authRoute.module, isA<AuthModule>());
      expect(dashboardRoute.module, isA<DashboardModule>());

      expect((authRoute.module as AuthModule).appBootstrap, same(fakeBootstrap));
      expect((dashboardRoute.module as DashboardModule).appBootstrap, same(fakeBootstrap));
    });
  });
}
