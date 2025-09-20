import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';

// Fake AuthGuard for testing
class FakeAuthGuard extends RouteGuard {
  FakeAuthGuard() : super(redirectTo: '/login');

  @override
  Future<bool> canActivate(String path, ParallelRoute route) async {
    return true; // Always allow navigation in tests
  }
}

void main() {
  setUp(() {
    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(EstimationModule(appBootstrap));
    Modular.replaceInstance(FakeAuthGuard());
    Modular.setInitialRoute(estimationLandingRoute);
  });

  tearDown(() {
    Modular.destroy();
  });

  test('estimationLandingRoute exists in EstimationModule', () {
    final module = EstimationModule(
      AppBootstrap(
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      ),
    );

    final routeExists = module.routeDefinitions.any(
      (routeDef) => routeDef.route == estimationLandingRoute,
    );

    expect(routeExists, isTrue);
  });
}
