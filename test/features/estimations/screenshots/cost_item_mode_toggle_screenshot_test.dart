import 'package:construculator/features/estimation/presentation/widgets/cost_item_mode_toggle.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 56);
  const ratio = 1.0;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpToggle(
    WidgetTester tester, {
    required bool fromCostFile,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: CostItemModeToggle(
              fromCostFile: fromCostFile,
              onFromCostFile: () {},
              onManually: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CostItemModeToggle Screenshot Tests - Light', () {
    testWidgets('manually active state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpToggle(tester, fromCostFile: false);

      await expectLater(
        find.byType(CostItemModeToggle),
        matchesGoldenFile(
          'goldens/cost_item_mode_toggle/${size.width}x${size.height}/cost_item_mode_toggle_manually_active.png',
        ),
      );
    });

    testWidgets('from cost file active state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpToggle(tester, fromCostFile: true);

      await expectLater(
        find.byType(CostItemModeToggle),
        matchesGoldenFile(
          'goldens/cost_item_mode_toggle/${size.width}x${size.height}/cost_item_mode_toggle_from_cost_file_active.png',
        ),
      );
    });
  });

  group('CostItemModeToggle Screenshot Tests - Dark', () {
    testWidgets('manually active state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpToggle(tester, fromCostFile: false, theme: createTestThemeDark());

      await expectLater(
        find.byType(CostItemModeToggle),
        matchesGoldenFile(
          'goldens/cost_item_mode_toggle/${size.width}x${size.height}/cost_item_mode_toggle_manually_active_dark.png',
        ),
      );
    });

    testWidgets('from cost file active state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpToggle(tester, fromCostFile: true, theme: createTestThemeDark());

      await expectLater(
        find.byType(CostItemModeToggle),
        matchesGoldenFile(
          'goldens/cost_item_mode_toggle/${size.width}x${size.height}/cost_item_mode_toggle_from_cost_file_active_dark.png',
        ),
      );
    });
  });
}
