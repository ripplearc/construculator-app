import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorModule', () {
    test('registers a single root route', () {
      // ignore: no_direct_instantiation
      final routeManager = RouteManager();

      CalculatorModule().routes(routeManager);

      expect(routeManager.allRoutes, hasLength(1));
      expect(routeManager.allRoutes.single, isA<ChildRoute>());
      expect(routeManager.allRoutes.single.name, equals('/'));
    });
  });
}
