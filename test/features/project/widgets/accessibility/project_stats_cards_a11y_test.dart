import 'package:construculator/features/project/presentation/widgets/project_stats_cards.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget buildWidget(ThemeData theme, {bool tappable = true}) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(
        child: ProjectStatsCards(
          estimationCount: 34,
          memberCount: 12,
          onEstimationsTap: tappable ? () {} : null,
          onMembersTap: tappable ? () {} : null,
        ),
      ),
    );
  }

  group('ProjectStatsCards – accessibility', () {
    testWidgets(
      'estimations card meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildWidget(theme),
          find.byKey(const Key('project_stats_estimations_card')),
        );
      },
    );

    testWidgets(
      'members card meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildWidget(theme),
          find.byKey(const Key('project_stats_members_card')),
        );
      },
    );
  });
}
