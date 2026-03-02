import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class FakeTabModuleLoader extends TabModuleManager {
  final List<ShellTab> loadedTabs = [];
  FakeTabModuleLoader(super.bootstrap);
  @override
  Future<void> ensureTabModuleLoaded(ShellTab tab) async {
    loadedTabs.add(tab);
  }

  @override
  bool isLoaded(ShellTab tab) => loadedTabs.contains(tab);
}

class _TestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<TabModuleManager>(
      () => FakeTabModuleLoader(Modular.get<AppBootstrap>()),
    );
    i.addLazySingleton<CurrentProjectNotifier>(
      () => FakeCurrentProjectNotifier(initialProjectId: 'test-project-id'),
    );
    i.addLazySingleton<AppBootstrap>(
      () => AppBootstrap(
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      ),
    );
  }
}

void main() {
  late FakeTabModuleLoader loader;

  setUp(() {
    Modular.destroy();
    Modular.init(_TestModule());
    loader = Modular.get<TabModuleManager>() as FakeTabModuleLoader;
  });

  Widget makeApp() {
    return MaterialApp(home: AppShellPage());
  }

  testWidgets('AppShellPage loads first tab module in initState', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(loader.loadedTabs.contains(ShellTab.home), isTrue);
  });

  testWidgets('AppShellPage loads tab module on tab tap', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.tap(find.text('Calculations'));
    await tester.pump();
    expect(loader.loadedTabs.contains(ShellTab.calculations), isTrue);
  });
}
