import 'package:construculator/features/project_settings/presentation/widgets/delete_project_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 80);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  Future<void> pumpButton({
    required WidgetTester tester,
    required ThemeData theme,
    bool isDeleting = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
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

  screenshotThemeGroups('DeleteProjectButton Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders enabled state', (tester) async {
      await pumpButton(tester: tester, theme: theme);

      await expectLater(
        find.byType(DeleteProjectButton),
        matchesGoldenFile(
          'goldens/delete_project_button/${size.width.toInt()}x${size.height.toInt()}/enabled$suffix.png',
        ),
      );
    });

    testWidgets('renders disabled state during deletion', (tester) async {
      await pumpButton(tester: tester, isDeleting: true, theme: theme);

      await expectLater(
        find.byType(DeleteProjectButton),
        matchesGoldenFile(
          'goldens/delete_project_button/${size.width.toInt()}x${size.height.toInt()}/disabled_deleting$suffix.png',
        ),
      );
    });
  });
}
