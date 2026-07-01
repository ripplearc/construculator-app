import 'package:construculator/features/dashboard/presentation/widgets/highlighted_project_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Project buildProject() {
    return Project(
      id: 'project-1',
      projectName: 'My project',
      creatorUserId: 'user-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 4, 29, 18, 11),
      status: ProjectStatus.active,
    );
  }

  Widget makeTestableWidget({
    required Widget child,
    required ThemeData theme,
  }) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('HighlightedProjectItem - accessibility', () {
    testWidgets('meets a11y guidelines for settings action in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: HighlightedProjectItem(
            project: buildProject(),
            onTap: () {},
            onSettingsTap: () {},
          ),
        ),
        find.bySemanticsLabel('Project settings'),
      );
    });

    testWidgets('meets a11y guidelines for project name text in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: HighlightedProjectItem(
            project: buildProject(),
            onTap: () {},
            onSettingsTap: () {},
          ),
        ),
        find.text('My project'),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });
  });
}
