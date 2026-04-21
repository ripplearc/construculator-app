import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/global_search/presentation/widgets/estimation_card_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('EstimationCard A11y Tests', () {
    final testDate = DateTime(2025, 4, 22, 14, 30);

    Widget createWidget(
      CostEstimate estimation, {
      String? ownerName,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EstimationCard(
            estimation: estimation,
            ownerName: ownerName,
            onTap: () {},
            onMenuTap: () {},
          ),
        ),
      );
    }

    testWidgets('a11y: base card passes in both themes', (tester) async {
      await setupA11yTest(tester);

      final estimation = CostEstimate.defaultEstimate(
        estimateName: '2nd Wall Cost',
        totalCost: 12343.88,
        createdAt: testDate,
        updatedAt: testDate,
      );

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(estimation, theme: theme),
        find.byType(EstimationCard),
      );
    });

    testWidgets('a11y: card with owner passes in both themes', (tester) async {
      await setupA11yTest(tester);

      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Kitchen Renovation',
        totalCost: 50000.0,
        createdAt: testDate,
        updatedAt: testDate,
      );

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(estimation, ownerName: 'Jane Smith', theme: theme),
        find.byType(EstimationCard),
      );
    });

    testWidgets('a11y: card with null cost passes in both themes', (tester) async {
      await setupA11yTest(tester);

      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Pending Estimate',
        totalCost: null,
        createdAt: testDate,
        updatedAt: testDate,
      );

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(estimation, theme: theme),
        find.byType(EstimationCard),
      );
    });

    testWidgets('a11y: card with long estimation name passes in both themes', (tester) async {
      await setupA11yTest(tester);

      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Complete Home Renovation and Extension Project Phase 2',
        totalCost: 250000.75,
        createdAt: testDate,
        updatedAt: testDate,
      );

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(estimation, theme: theme),
        find.byType(EstimationCard),
      );
    });

    testWidgets('a11y: card with owner and long name passes in light theme', (tester) async {
      await setupA11yTest(tester);

      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Complete Home Renovation and Extension Project Phase 2',
        totalCost: 75000.0,
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        createWidget(
          estimation,
          ownerName: 'Mr. Alexander Von Humboldt-Richardson Jr.',
          theme: createTestTheme(),
        ),
      );
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(EstimationCard),
      );
    });
  });
}
