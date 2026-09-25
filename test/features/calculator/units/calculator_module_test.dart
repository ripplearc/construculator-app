import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('CalculatorModule', () {
    test('registers a single root route', () {
      // ignore: no_direct_instantiation
      final routeManager = RouteManager();
      CalculatorModule(FakeAppBootstrapFactory.create()).routes(routeManager);

      expect(routeManager.allRoutes, hasLength(1));
      expect(routeManager.allRoutes.single, isA<ChildRoute>());
      expect(routeManager.allRoutes.single.name, equals('/'));
    });

    test('binds one preferences repository over the auth library', () {
      final clock = FakeClockImpl();
      final authNotifier = FakeAuthNotifier();
      final authManager = FakeAuthManager(
        authNotifier: authNotifier,
        authRepository: FakeAuthRepository(clock: clock),
        wrapper: FakeSupabaseWrapper(clock: clock),
        clock: clock,
      );
      Modular.init(CalculatorModule(FakeAppBootstrapFactory.create()));
      Modular.replaceInstance<AuthNotifier>(authNotifier);
      Modular.replaceInstance<AuthManager>(authManager);
      addTearDown(Modular.destroy);

      final repository = Modular.get<CalculatorPreferencesRepository>();
      expect(repository, same(Modular.get<CalculatorPreferencesRepository>()));
    });

    test('disposes the repository with the module', () async {
      final clock = FakeClockImpl();
      final authNotifier = FakeAuthNotifier();
      final authManager = FakeAuthManager(
        authNotifier: authNotifier,
        authRepository: FakeAuthRepository(clock: clock),
        wrapper: FakeSupabaseWrapper(clock: clock),
        clock: clock,
      );
      Modular.init(CalculatorModule(FakeAppBootstrapFactory.create()));
      Modular.replaceInstance<AuthNotifier>(authNotifier);
      Modular.replaceInstance<AuthManager>(authManager);
      var done = false;
      Modular.get<CalculatorPreferencesRepository>().watchPreferences().listen(
        (_) {},
        onDone: () => done = true,
      );

      Modular.destroy();
      await pumpEventQueue();

      expect(done, isTrue);
    });
  });
}
