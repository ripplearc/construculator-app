import 'package:construculator/features/project_settings/presentation/widgets/project_creation_success_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  group('ProjectCreationSuccessSheetContent Screenshot Tests', () {
    final size = const Size(390, 520);
    const ratio = 1.0;

    Future<void> pumpSuccessSheet({required WidgetTester tester}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProjectCreationSuccessSheetContent(
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
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpSuccessSheet(tester: tester);

      await expectLater(
        find.byType(ProjectCreationSuccessSheetContent),
        matchesGoldenFile(
          'goldens/project_creation_success_sheet/${size.width}x${size.height}/project_creation_success_sheet.png',
        ),
      );
    });
  });

  group('ProjectCreationSuccessSheet Popup Screenshot Tests', () {
    final size = const Size(390, 844);
    const ratio = 1.0;

    testWidgets('renders success sheet as popup over background', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: createTestTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  key: const Key('open_sheet_button'),
                  onPressed: () {
                    ProjectCreationSuccessSheet.show(
                      context,
                      onContinue: () {},
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/project_creation_success_sheet/${size.width}x${size.height}/project_creation_success_sheet_popup.png',
        ),
      );
    });
  });
}
