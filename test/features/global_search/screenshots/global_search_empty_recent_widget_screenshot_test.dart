import 'package:construculator/features/global_search/presentation/widgets/global_search_empty_recent_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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

  group('GlobalSearchEmptyRecentWidget Screenshot Tests', () {
    Future<void> pumpEmptyRecentWidget({required WidgetTester tester}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: GlobalSearchEmptyRecentWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();
    }

    testWidgets('renders empty recent state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpEmptyRecentWidget(tester: tester);

      await expectLater(
        find.byType(GlobalSearchEmptyRecentWidget),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });
  });
}
