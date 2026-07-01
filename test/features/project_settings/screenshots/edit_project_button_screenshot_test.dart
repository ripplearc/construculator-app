import 'package:construculator/features/project_settings/presentation/widgets/edit_project_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 80);
  const ratio = 1.0;

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget wrap(ThemeData theme) => MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: EditProjectButton(onPressed: () async {}),
          ),
        ),
      );

  void setSize(WidgetTester tester) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('EditProjectButton screenshot tests', () {
    testWidgets('light theme', (tester) async {
      setSize(tester);
      await tester.pumpWidget(wrap(createTestTheme()));
      await tester.pump();

      await expectLater(
        find.byType(EditProjectButton),
        matchesGoldenFile(
          'goldens/edit_project_button/${size.width}x${size.height}/edit_project_button_light.png',
        ),
      );
    });

    testWidgets('dark theme', (tester) async {
      setSize(tester);
      await tester.pumpWidget(wrap(createTestThemeDark()));
      await tester.pump();

      await expectLater(
        find.byType(EditProjectButton),
        matchesGoldenFile(
          'goldens/edit_project_button/${size.width}x${size.height}/edit_project_button_dark.png',
        ),
      );
    });
  });
}
