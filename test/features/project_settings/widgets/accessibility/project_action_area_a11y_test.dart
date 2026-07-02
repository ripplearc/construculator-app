import 'package:construculator/features/project_settings/presentation/widgets/project_action_area.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  BuildContext? buildContext;

  Widget createWidget({ThemeData? theme}) => MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: ProjectActionArea(),
              ),
            );
          },
        ),
      );

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  tearDown(() {
    buildContext = null;
  });

  group('ProjectActionArea accessibility', () {
    testWidgets('add description button meets a11y guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(theme: theme),
        find.text(l10n().addDescriptionButton),
      );
    });

    testWidgets('invite member button meets a11y guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(theme: theme),
        find.text(l10n().inviteMemberButton),
      );
    });
  });
}
