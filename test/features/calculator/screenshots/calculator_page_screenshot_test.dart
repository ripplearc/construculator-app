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
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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

  group('CalculatorPage Screenshot Tests - Light', () {
    testWidgets('renders initial state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/calculator_page/${size.width}x${size.height}/calculator_page_initial_light.png',
        ),
      );
    });
  });

  group('CalculatorPage Screenshot Tests - Dark', () {
    testWidgets('renders initial state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester, theme: createTestThemeDark());

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/calculator_page/${size.width}x${size.height}/calculator_page_initial_dark.png',
        ),
      );
    });
  });
}
