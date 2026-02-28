import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class MockTabModuleLoader extends TabModuleLoader {
  final List<ShellTab> loadedTabs;
  MockTabModuleLoader() : loadedTabs = [], super(MockAppBootstrap());
  @override
  Future<void> ensureTabModuleLoaded(ShellTab tab) async {
    loadedTabs.add(tab);
  }

  @override
  bool isLoaded(ShellTab tab) => loadedTabs.contains(tab);
}

class MockAppBootstrap extends AppBootstrap {}

void main() {
  testWidgets('AppShellPage loads first tab module in initState', (
    tester,
  ) async {
    Modular.init(MockModule());
    Modular.bindModule(MockModule());
    Modular.bindSingleton<TabModuleLoader>(MockTabModuleLoader());
    await tester.pumpWidget(const MaterialApp(home: AppShellPage()));
    // Should show loader for first tab
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppShellPage loads tab module on tab tap', (tester) async {
    Modular.init(MockModule());
    Modular.bindModule(MockModule());
    final loader = MockTabModuleLoader();
    Modular.bindSingleton<TabModuleLoader>(loader);
    await tester.pumpWidget(const MaterialApp(home: AppShellPage()));
    // Simulate tab tap
    await tester.tap(find.text('Calculations'));
    await tester.pump();
    expect(loader.loadedTabs.contains(ShellTab.calculations), isTrue);
  });
}
