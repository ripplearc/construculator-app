import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/default_tab_providers.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/libraries/analytics/current_screen_tracker.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/testing/fake_feature_flag_repository.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/sentry/fake_sentry_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('TabModuleManager', () {
    group('with default providers', () {
      late TabModuleManager manager;

      setUp(() {
        final appBootstrap = AppBootstrap(
          config: FakeAppConfig(),
          envLoader: FakeEnvLoader(),
          sentryWrapper: FakeSentryWrapper(),
          supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          analyticsRepository: const NoOpAnalyticsRepository(),
          powerSyncDatabase: FakePowerSyncDatabase(),
          featureFlagRepository: FakeFeatureFlagRepository(),
          currentScreenTracker: CurrentScreenTracker(),
        );
        Modular.init(ShellModule(appBootstrap));
        manager = Modular.get<TabModuleManager>();
      });

      tearDown(() {
        Modular.destroy();
      });

      group('ensureTabModuleLoaded', () {
        test('loads each tab only once', () async {
          await manager.ensureTabModuleLoaded(ShellTab.calculations);
          expect(manager.isLoaded(ShellTab.calculations), isTrue);
          await manager.ensureTabModuleLoaded(ShellTab.calculations);
          expect(manager.isLoaded(ShellTab.calculations), isTrue);
        });
      });

      group('isLoaded', () {
        test('returns false for unaccessed tabs', () {
          expect(manager.isLoaded(ShellTab.estimates), isFalse);
        });
        test('returns true after loading each tab', () async {
          await manager.ensureTabModuleLoaded(ShellTab.calculations);
          expect(manager.isLoaded(ShellTab.calculations), isTrue);

          await manager.ensureTabModuleLoaded(ShellTab.estimates);
          expect(manager.isLoaded(ShellTab.estimates), isTrue);
        });
      });

      group('activeTabs', () {
        test('includes every tab that has a registered provider, in '
            'ShellTab.values order', () {
          expect(manager.activeTabs, [ShellTab.calculations, ShellTab.estimates]);
        });
      });
    });

    group('with custom providers', () {
      late _FakeTabModuleProvider fakeProvider;
      late TabModuleManager customManager;

      setUp(() {
        final appBootstrap = AppBootstrap(
          config: FakeAppConfig(),
          envLoader: FakeEnvLoader(),
          sentryWrapper: FakeSentryWrapper(),
          supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          analyticsRepository: const NoOpAnalyticsRepository(),
          powerSyncDatabase: FakePowerSyncDatabase(),
          featureFlagRepository: FakeFeatureFlagRepository(),
          currentScreenTracker: CurrentScreenTracker(),
        );
        Modular.init(_TestShellModule(appBootstrap));
        customManager = Modular.get<TabModuleManager>();
        fakeProvider = Modular.get<_FakeTabModuleProvider>();
      });

      tearDown(() {
        Modular.destroy();
      });

      test('calls provider.load() exactly once per tab', () async {
        await customManager.ensureTabModuleLoaded(ShellTab.calculations);
        await customManager.ensureTabModuleLoaded(ShellTab.calculations);
        expect(fakeProvider.loadCallCount, 1);
      });
    });

    group('minimum-tab floor', () {
      // CoreBottomNavBar (CA-874) only supports 2-4 tabs. This must be a
      // real, unconditional check — not `assert()`, which is stripped from
      // release/profile builds — so asserting on the concrete exception
      // type (StateError, not merely "some error") guards against a
      // regression to a bare `assert()`: an AssertionError would fail this
      // `isA<StateError>()` check even though asserts run in test mode.
      test('throws StateError when constructed with zero providers', () {
        expect(
          // ignore: no_direct_instantiation
          () => TabModuleManager(
            FakeAppBootstrapFactory.create(),
            providers: const {},
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('at least 2 tab providers'),
            ),
          ),
        );
      });

      test('throws StateError when constructed with only one provider', () {
        expect(
          // ignore: no_direct_instantiation
          () => TabModuleManager(
            FakeAppBootstrapFactory.create(),
            providers: const {ShellTab.calculations: NoOpTabModuleProvider()},
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('does not throw when constructed with two providers', () {
        expect(
          // ignore: no_direct_instantiation
          () => TabModuleManager(
            FakeAppBootstrapFactory.create(),
            providers: const {
              ShellTab.calculations: NoOpTabModuleProvider(),
              ShellTab.estimates: NoOpTabModuleProvider(),
            },
          ),
          returnsNormally,
        );
      });
    });
  });
}

class _FakeTabModuleProvider implements TabModuleProvider {
  int loadCallCount = 0;
  @override
  Future<void> load(AppBootstrap _) async => loadCallCount++;

  // Unused by these tests, which only exercise load()/isLoaded() bookkeeping.
  @override
  Widget buildRoot(BuildContext _) => const SizedBox.shrink();
}

class _TestShellModule extends Module {
  final AppBootstrap appBootstrap;

  _TestShellModule(this.appBootstrap);

  @override
  void binds(Injector i) {
    i.addSingleton<_FakeTabModuleProvider>(() => _FakeTabModuleProvider());
    i.addSingleton<TabModuleManager>(
      () => TabModuleManager(
        appBootstrap,
        providers: {
          ShellTab.calculations: i.get<_FakeTabModuleProvider>(),
          // Only calculations' load-call-count is asserted on below; this
          // second entry exists solely to satisfy the minimum-tab-floor
          // check.
          ShellTab.estimates: i.get<_FakeTabModuleProvider>(),
        },
      ),
    );
  }
}
