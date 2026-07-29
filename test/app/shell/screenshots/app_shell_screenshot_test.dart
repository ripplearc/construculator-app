import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 80);
  const ratio = 1.0;
  const testName = 'app_shell_bottom_nav';

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpBottomNav({
    required WidgetTester tester,
    required ThemeData theme,
    int selectedIndex = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(CoreSpacing.space4),
              child: CoreBottomNavBar(
                tabs: [
                  BottomNavTab(
                    icon: CoreIcons.calculation,
                    label: AppLocalizations.of(context)!.calculationsTab,
                  ),
                  BottomNavTab(
                    icon: CoreIcons.cost,
                    label: AppLocalizations.of(context)!.estimatesTab,
                  ),
                ],
                selectedIndex: selectedIndex,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppShell BottomNavBar Screenshot Tests - Light', () {
    testWidgets('calculations tab selected', (tester) async {
      await pumpBottomNav(tester: tester, theme: createTestTheme());

      await expectLater(
        find.byType(CoreBottomNavBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_calculations_light.png',
        ),
      );
    });

    testWidgets('estimates tab selected', (tester) async {
      await pumpBottomNav(
        tester: tester,
        theme: createTestTheme(),
        selectedIndex: 1,
      );

      await expectLater(
        find.byType(CoreBottomNavBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_estimates_light.png',
        ),
      );
    });
  });

  group('AppShell BottomNavBar Screenshot Tests - Dark', () {
    testWidgets('calculations tab selected', (tester) async {
      await pumpBottomNav(tester: tester, theme: createTestThemeDark());

      await expectLater(
        find.byType(CoreBottomNavBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_calculations_dark.png',
        ),
      );
    });

    testWidgets('estimates tab selected', (tester) async {
      await pumpBottomNav(
        tester: tester,
        theme: createTestThemeDark(),
        selectedIndex: 1,
      );

      await expectLater(
        find.byType(CoreBottomNavBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_estimates_dark.png',
        ),
      );
    });
  });
}
