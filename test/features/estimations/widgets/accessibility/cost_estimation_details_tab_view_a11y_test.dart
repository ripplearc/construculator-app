import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_details_tab_view.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  BuildContext? buildContext;
  group('CostEstimationDetailsTabView A11y Tests', () {
    Widget createWidget({ThemeData? theme}) {
      return MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return const Scaffold(body: CostEstimationDetailsTabView());
          },
        ),
      );
    }

    AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

    testWidgets('a11y: tab view passes in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(theme: theme),
        find.byType(CostEstimationDetailsTabView),
      );
    });

    testWidgets('a11y: materials tab passes', (tester) async {
      await setupA11yTest(tester);

      await tester.pumpWidget(createWidget(theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationDetailsTabView),
      );
    });

    testWidgets('a11y: labours tab passes', (tester) async {
      await setupA11yTest(tester);

      await tester.pumpWidget(createWidget(theme: createTestTheme()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n().laboursTab));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationDetailsTabView),
      );
    });

    testWidgets('a11y: equipments tab passes', (tester) async {
      await setupA11yTest(tester);

      await tester.pumpWidget(createWidget(theme: createTestTheme()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n().equipmentsTab));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationDetailsTabView),
      );
    });

    testWidgets('a11y: page passes in both themes', (tester) async {
      await setupA11yTest(tester);

      await tester.pumpWidget(createWidget(theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byKey(const Key('cost_estimation_details_tab_view')),
      );
    });
  });
}
