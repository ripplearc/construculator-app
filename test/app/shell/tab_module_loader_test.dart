import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/tab_module_loader.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _TabModuleLoaderTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<AppBootstrap>(
      () => AppBootstrap(
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      ),
    );
    i.addLazySingleton<TabModuleLoader>(
      () => TabModuleLoader(i.get<AppBootstrap>()),
    );
  }
}

void main() {
  late TabModuleLoader loader;

  setUp(() {
    Modular.init(_TabModuleLoaderTestModule());
    loader = Modular.get<TabModuleLoader>();
  });

  tearDown(() {
    Modular.destroy();
  });

  group('TabModuleLoader', () {
    group('ensureTabModuleLoaded', () {
      test('loads each tab only once', () async {
        await loader.ensureTabModuleLoaded(ShellTab.home);
        expect(loader.isLoaded(ShellTab.home), isTrue);
        await loader.ensureTabModuleLoaded(ShellTab.home);
        expect(loader.isLoaded(ShellTab.home), isTrue);
      });
    });

    group('isLoaded', () {
      test('returns false for unaccessed tabs', () {
        expect(loader.isLoaded(ShellTab.calculations), isFalse);
        expect(loader.isLoaded(ShellTab.estimation), isFalse);
        expect(loader.isLoaded(ShellTab.members), isFalse);
      });
    });
  });
}
