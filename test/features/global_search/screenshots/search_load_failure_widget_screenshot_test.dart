import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_load_failure_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const testName = 'search_load_failure_widget';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  group('SearchLoadFailureWidget Screenshot Tests', () {
    Future<void> pumpFailureWidget({required WidgetTester tester}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SearchLoadFailureWidget(onRetry: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();
    }

    testWidgets('renders the persistent failure body correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpFailureWidget(tester: tester);

      await expectLater(
        find.byType(SearchLoadFailureWidget),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });
  });
}
