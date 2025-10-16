import 'package:construculator/app/app_module.dart';
import 'package:construculator/app/testing/fake_app_bootstrap.dart';
import 'package:construculator/libraries/router/testing/fake_route_manager.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeRouteManager fakeRouteManager;

  setUp(() {
    fakeRouteManager = FakeRouteManager();
  });

  group('FakeRouteManager', () {
    test('initial state should be empty', () {
      expect(fakeRouteManager.addedRoutes, isEmpty);
    });

    test('add() should add a route to the list', () {
      final route = ModuleRoute('/test', module: AppModule(FakeAppBootstrap()));

      fakeRouteManager.add(route);

      expect(fakeRouteManager.addedRoutes, hasLength(1));
      expect(fakeRouteManager.addedRoutes.first, same(route));
    });

    test('reset() should clear all added routes', () {
      final route = ModuleRoute('/test', module: AppModule(FakeAppBootstrap()));
      fakeRouteManager.add(route);
      expect(fakeRouteManager.addedRoutes, isNotEmpty);

      fakeRouteManager.reset();

      expect(fakeRouteManager.addedRoutes, isEmpty);
    });
  });
}
