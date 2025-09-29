import 'package:construculator/app/app_bootstrap.dart'; 
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';


void main() {
  late AppBootstrap appBootstrap;

  setUp(() {
    appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    
    final testEstimationModule = EstimationModule(appBootstrap);
    
    Modular.init(testEstimationModule);
    Modular.setInitialRoute(estimationLandingRoute);
  });

  tearDown(() {
    Modular.destroy();
  });

  group('EstimationModule Route Tests', () {
    test('estimationLandingRoute exists in EstimationModule', () {
      final module = EstimationModule(appBootstrap);

      final routeExists = module.routeDefinitions.any(
        (routeDef) => routeDef.route == estimationLandingRoute,
      );

      expect(routeExists, isTrue);
    });

    test('estimationLandingRoute has correct route path', () {
      final module = EstimationModule(appBootstrap);
      final routeDef = module.routeDefinitions.firstWhere(
        (routeDef) => routeDef.route == estimationLandingRoute,
      );

      expect(routeDef.route, equals(estimationLandingRoute));
    });

    test('estimationLandingRoute has AuthGuard', () {
      final module = EstimationModule(appBootstrap);
      final routeDef = module.routeDefinitions.firstWhere(
        (routeDef) => routeDef.route == estimationLandingRoute,
      );

      expect(routeDef.guards, isNotEmpty);
      expect(routeDef.guards.length, equals(1));
    });
  });
}
