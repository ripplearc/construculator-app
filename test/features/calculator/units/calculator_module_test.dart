import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../helpers/fake_trade_stores_database.dart';

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

    group('bindings', () {
      late FakeTradeStoresDatabase database;

      setUp(() {
        final clock = FakeClockImpl();
        final authNotifier = FakeAuthNotifier();
        final authManager = FakeAuthManager(
          authNotifier: authNotifier,
          authRepository: FakeAuthRepository(clock: clock),
          wrapper: FakeSupabaseWrapper(clock: clock),
          clock: clock,
        );
        database = FakeTradeStoresDatabase();
        final supabaseWrapper = FakeSupabaseWrapper(clock: clock)
          ..setInternalUserId('user-1');
        Modular.init(
          CalculatorModule(
            FakeAppBootstrapFactory.create(
              supabaseWrapper: supabaseWrapper,
              powerSyncDatabase: database,
            ),
          ),
        );
        Modular.replaceInstance<AuthNotifier>(authNotifier);
        Modular.replaceInstance<AuthManager>(authManager);
        // Modular keeps the first test's database across destroy; without
        // this every later test would run on a closed one.
        Modular.replaceInstance<PowerSyncDatabase>(database);
      });

      tearDown(() async {
        Modular.destroy();
        await database.closeChanges();
      });

      test('binds one preferences repository over the auth library', () {
        final repository = Modular.get<CalculatorPreferencesRepository>();
        expect(
          repository,
          same(Modular.get<CalculatorPreferencesRepository>()),
        );
      });

      test('binds one trade stores repository over PowerSync', () {
        final repository = Modular.get<TradeStoresRepository>();
        expect(repository, same(Modular.get<TradeStoresRepository>()));
      });

      test('disposes the trade stores with the module', () async {
        final spacings = Modular.get<TradeStoresRepository>().watchSpacings();
        final ended = expectLater(
          spacings,
          emitsInOrder([hasLength(2), emitsDone]),
        );
        await expectLater(spacings, emits(hasLength(2)));

        Modular.destroy();

        await ended;
      });

      test('disposes the repository with the module', () async {
        final ended = expectLater(
          Modular.get<CalculatorPreferencesRepository>().watchPreferences(),
          emitsInOrder([anything, emitsDone]),
        );

        Modular.destroy();

        await ended;
      });
    });
  });
}
