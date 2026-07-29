import 'package:construculator/features/app_header/presentation/widgets/title_search_app_bar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 100);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> pumpTitleSearchAppBar({
    required WidgetTester tester,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          appBar: TitleSearchAppBar(),
          body: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('TitleSearchAppBar Screenshot Tests', (theme, suffix) {
    testWidgets('renders correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpTitleSearchAppBar(tester: tester, theme: theme);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/title_search_app_bar/${size.width}x${size.height}/title_search_app_bar$suffix.png',
        ),
      );
    });
  });
}
