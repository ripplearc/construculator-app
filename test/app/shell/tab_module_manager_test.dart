import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _TabModuleManagerTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<AppBootstrap>(
      () => AppBootstrap(
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      ),
    );
    i.addLazySingleton<TabModuleManager>(
      () => TabModuleManager(i.get<AppBootstrap>()),
    );
  }
}

void main() {
  late TabModuleManager manager;

  setUp(() {
    Modular.init(_TabModuleManagerTestModule());
    manager = Modular.get<TabModuleManager>();
  });

  tearDown(() {
    Modular.destroy();
  });

  group('TabModuleManager', () {
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
    });
  });
}
