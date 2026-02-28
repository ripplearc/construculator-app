import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/tab_module_loader.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';

void main() {
  late TabModuleLoader loader;
  late AppBootstrap appBootstrap;

  setUp(() {
    appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    loader = TabModuleLoader(appBootstrap);
  });

  test('loads each tab only once', () async {
    await loader.ensureTabModuleLoaded(ShellTab.home);
    expect(loader.isLoaded(ShellTab.home), isTrue);
    await loader.ensureTabModuleLoaded(ShellTab.home);
    expect(loader.isLoaded(ShellTab.home), isTrue);
  });

  test('does not load unaccessed tabs', () {
    expect(loader.isLoaded(ShellTab.calculations), isFalse);
    expect(loader.isLoaded(ShellTab.estimation), isFalse);
    expect(loader.isLoaded(ShellTab.members), isFalse);
  });
}
