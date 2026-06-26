import 'package:construculator/features/project_settings/presentation/widgets/project_creation_success_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 520);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  group('ProjectCreationSuccessSheetContent Screenshot Tests', () {
    Future<void> pumpSuccessSheet({required WidgetTester tester}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProjectCreationSuccessSheetContent(
              onBackToCalculation: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();
    }

    testWidgets('renders success sheet correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpSuccessSheet(tester: tester);

      await expectLater(
        find.byType(ProjectCreationSuccessSheetContent),
        matchesGoldenFile(
          'goldens/project_creation_success_sheet/${size.width}x${size.height}/project_creation_success_sheet.png',
        ),
      );
    });
  });
}
