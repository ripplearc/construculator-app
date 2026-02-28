import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_loader.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class FakeTabModuleLoader extends TabModuleLoader {
  final List<ShellTab> loadedTabs = [];
  FakeTabModuleLoader(super.bootstrap);
  @override
  Future<void> ensureTabModuleLoaded(ShellTab tab) async {
    loadedTabs.add(tab);
  }

  @override
  bool isLoaded(ShellTab tab) => loadedTabs.contains(tab);
}

class _TestModule extends Module {}

void main() {
  late AppBootstrap appBootstrap;
  late FakeTabModuleLoader loader;

  setUp(() {
    appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    loader = FakeTabModuleLoader(appBootstrap);
    Modular.init(_TestModule());
    Modular.bindModule(_TestModule());
    Modular.replaceInstance<TabModuleLoader>(loader);
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
