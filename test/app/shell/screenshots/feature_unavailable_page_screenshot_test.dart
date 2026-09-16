import 'package:construculator/app/shell/feature_unavailable_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const testName = 'feature_unavailable_page';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpFeatureUnavailablePage({
    required WidgetTester tester,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FeatureUnavailablePage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  screenshotThemeGroups('FeatureUnavailablePage Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders the not-available message', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpFeatureUnavailablePage(tester: tester, theme: theme);

      await expectLater(
        find.byType(FeatureUnavailablePage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/$testName$suffix.png',
        ),
      );
    });
  });
}
