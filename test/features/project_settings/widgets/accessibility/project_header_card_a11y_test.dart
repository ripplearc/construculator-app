import 'package:construculator/features/project_settings/presentation/widgets/project_header_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget makeTestableWidget({required ThemeData theme}) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProjectHeaderCard(
          projectName: 'Material of building',
          description: 'A short description.',
          lastUpdatedAt: DateTime(2024, 10, 12, 14, 30),
          estimationCount: 34,
          memberCount: 12,
        ),
      ),
    );
  }

  group('ProjectHeaderCard - accessibility', () {
    testWidgets('project name meets guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.text('Material of building'),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('last-updated line meets guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.byKey(ProjectHeaderCard.lastUpdatedKey),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });
  });
}
