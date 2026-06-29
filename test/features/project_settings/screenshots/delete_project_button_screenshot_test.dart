import 'package:construculator/features/project_settings/presentation/widgets/delete_project_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('DeleteProjectButton Screenshot Tests', () {
    const size = Size(390, 80);
    const ratio = 1.0;

    Future<void> pumpButton({
      required WidgetTester tester,
      bool isDeleting = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: DeleteProjectButton(
                projectName: 'Material of Building',
                canDelete: true,
                isDeleting: isDeleting,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders enabled state', (tester) async {
      await pumpButton(tester: tester);

      await expectLater(
        find.byType(DeleteProjectButton),
        matchesGoldenFile(
          'goldens/delete_project_button/${size.width.toInt()}x${size.height.toInt()}/enabled.png',
        ),
      );
    });

    testWidgets('renders disabled state during deletion', (tester) async {
      await pumpButton(tester: tester, isDeleting: true);

      await expectLater(
        find.byType(DeleteProjectButton),
        matchesGoldenFile(
          'goldens/delete_project_button/${size.width.toInt()}x${size.height.toInt()}/disabled_deleting.png',
        ),
      );
    });
  });
}
