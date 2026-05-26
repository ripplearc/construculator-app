import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/sentry/fake_sentry_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

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
        );
        Modular.init(ShellModule(appBootstrap));
        manager = Modular.get<TabModuleManager>();
      });

      tearDown(() {
        Modular.destroy();
      });

      group('ensureTabModuleLoaded', () {
        test('loads each tab only once', () async {
          await manager.ensureTabModuleLoaded(ShellTab.home);
          expect(manager.isLoaded(ShellTab.home), isTrue);
          await manager.ensureTabModuleLoaded(ShellTab.home);
          expect(manager.isLoaded(ShellTab.home), isTrue);
        });
      });

      group('isLoaded', () {
        test('returns false for unaccessed tabs', () {
          expect(manager.isLoaded(ShellTab.calculations), isFalse);
          expect(manager.isLoaded(ShellTab.estimation), isFalse);
          expect(manager.isLoaded(ShellTab.members), isFalse);
        });
        test('returns true after loading each tab', () async {
          await manager.ensureTabModuleLoaded(ShellTab.calculations);
          expect(manager.isLoaded(ShellTab.calculations), isTrue);

          await manager.ensureTabModuleLoaded(ShellTab.estimation);
          expect(manager.isLoaded(ShellTab.estimation), isTrue);

          await manager.ensureTabModuleLoaded(ShellTab.members);
          expect(manager.isLoaded(ShellTab.members), isTrue);
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
        );
        Modular.init(_TestShellModule(appBootstrap));
        customManager = Modular.get<TabModuleManager>();
        fakeProvider = Modular.get<_FakeTabModuleProvider>();
      });

      tearDown(() {
        Modular.destroy();
      });

      test('calls provider.load() exactly once per tab', () async {
        await customManager.ensureTabModuleLoaded(ShellTab.home);
        await customManager.ensureTabModuleLoaded(ShellTab.home);
        expect(fakeProvider.loadCallCount, 1);
      });
    });
  });
}

class _FakeTabModuleProvider implements TabModuleProvider {
  int loadCallCount = 0;
  @override
  Future<void> load(AppBootstrap _) async => loadCallCount++;
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
        providers: {ShellTab.home: i.get<_FakeTabModuleProvider>()},
      ),
    );
  }
}
