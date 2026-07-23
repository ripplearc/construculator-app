import 'package:construculator/features/global_search/presentation/widgets/global_search_empty_recent_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const testName = 'global_search_empty_recent_widget';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpEmptyRecentWidget({
    required WidgetTester tester,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: const GlobalSearchEmptyRecentWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('GlobalSearchEmptyRecentWidget Screenshot Tests - Light', () {
    testWidgets('renders empty recent state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpEmptyRecentWidget(tester: tester);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });
  });

  group('GlobalSearchEmptyRecentWidget Screenshot Tests - Dark', () {
    testWidgets('renders empty recent state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpEmptyRecentWidget(tester: tester, theme: createTestThemeDark());

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default_dark.png',
        ),
      );
    });
  });
}
