import 'package:construculator/features/project_settings/presentation/widgets/project_header_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 340);
  const ratio = 1.0;

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpProjectHeaderCard({
    required WidgetTester tester,
    required ThemeData theme,
    String? description,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProjectHeaderCard(
            projectName: 'Material of building',
            description: description,
            lastUpdatedAt: DateTime(2024, 10, 12, 14, 30),
            estimationCount: 34,
            memberCount: 12,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('ProjectHeaderCard Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders with description', (tester) async {
      await pumpProjectHeaderCard(
        tester: tester,
        theme: theme,
        description:
            'Lorem Ipsum is simply dummy text of the printing and '
            'typesetting industry. Lorem Ipsum has been the',
      );

      await expectLater(
        find.byType(ProjectHeaderCard),
        matchesGoldenFile(
          'goldens/project_header_card/${size.width}x${size.height}/with_description$suffix.png',
        ),
      );
    });
  });

  // This scenario only ever had a light golden; screenshotThemeGroups always
  // produces both light and dark, so it stays outside it rather than gaining
  // a new dark golden as a side effect of this migration.
  group('ProjectHeaderCard Screenshot Tests - Light Only', () {
    testWidgets('renders without description', (tester) async {
      await pumpProjectHeaderCard(tester: tester, theme: createTestTheme());

      await expectLater(
        find.byType(ProjectHeaderCard),
        matchesGoldenFile(
          'goldens/project_header_card/${size.width}x${size.height}/no_description.png',
        ),
      );
    });
  });
}
