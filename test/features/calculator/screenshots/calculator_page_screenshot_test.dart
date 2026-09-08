import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCalculatorPage({
    required WidgetTester tester,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalculatorPage(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() async {
    await loadAppFontsAll();
  });

  screenshotThemeGroups('CalculatorPage Screenshot Tests', (theme, suffix) {
    testWidgets('renders initial state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester, theme: theme);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/calculator_page/${size.width}x${size.height}/calculator_page_initial$suffix.png',
        ),
      );
    });
  });
}
