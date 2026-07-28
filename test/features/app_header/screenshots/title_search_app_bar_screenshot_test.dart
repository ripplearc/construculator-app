import 'package:construculator/features/app_header/presentation/widgets/title_search_app_bar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 56);
  const ratio = 1.0;
  const testName = 'title_search_app_bar';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget makeTestableWidget({required ThemeData theme}) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: TitleSearchAppBar(onSearchTap: () {}),
        body: const SizedBox.shrink(),
      ),
    );
  }

  group('TitleSearchAppBar Screenshot Tests', () {
    testWidgets('renders title and search action in light theme', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableWidget(theme: createTestTheme()));
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(TitleSearchAppBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_light.png',
        ),
      );
    });

    testWidgets('renders title and search action in dark theme', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableWidget(theme: createTestThemeDark()));
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(TitleSearchAppBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_dark.png',
        ),
      );
    });
  });
}
