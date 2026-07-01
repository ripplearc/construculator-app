import 'package:construculator/features/project_settings/presentation/widgets/project_action_area.dart';
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
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: ProjectActionArea(),
          ),
        ),
      );

  void setSize(WidgetTester tester) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('ProjectActionArea screenshot tests', () {
    testWidgets('light theme', (tester) async {
      setSize(tester);
      await tester.pumpWidget(wrap(createTestTheme()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectActionArea),
        matchesGoldenFile(
          'goldens/project_action_area/${size.width}x${size.height}/project_action_area_light.png',
        ),
      );
    });

    testWidgets('dark theme', (tester) async {
      setSize(tester);
      await tester.pumpWidget(wrap(createTestThemeDark()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectActionArea),
        matchesGoldenFile(
          'goldens/project_action_area/${size.width}x${size.height}/project_action_area_dark.png',
        ),
      );
    });
  });
}
