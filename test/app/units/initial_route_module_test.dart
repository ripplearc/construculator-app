import 'package:construculator/app/initial_route_module.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveInitialRoute', () {
    test('returns login route when unauthenticated', () {
      final route = resolveInitialRoute(false);

      expect(route, fullLoginRoute);
    });

    test('returns dashboard route when authenticated', () {
      final route = resolveInitialRoute(true);

      expect(route, fullDashboardRoute);
    });
  });
}
