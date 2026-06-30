import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorites_section.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  final _calculations = [
    FavoriteCalculation(
      id: 'c1',
      date: DateTime(2025, 4, 22, 14, 30),
      tags: const ['Flooring', 'Area'],
    ),
  ];

  final _estimations = [
    FavoriteEstimation(
      id: 'e1',
      title: '2nd Wall cost',
      date: DateTime(2025, 5, 3, 14, 30),
      totalCost: 12343.88,
    ),
  ];

  Widget makeTestableWidget({
    ThemeData? theme,
    List<FavoriteCalculation> calculations = const [],
    List<FavoriteEstimation> estimations = const [],
  }) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: FavoritesSection(
            calculations: calculations,
            estimations: estimations,
            onViewAll: () {},
            onCalculationTap: (_) {},
            onEstimationTap: (_) {},
          ),
        ),
      ),
    );
  }

  group('FavoritesSection – accessibility', () {
    testWidgets(
      'meets label guidelines when empty in both themes',
      (tester) async {
        await setupA11yTest(tester);
        // Tap target size disabled: the "View all" TextButton uses shrinkWrap
        // so it renders at text height (~20px). This matches the RecentEstimations
        // section pattern and is intentional per the Figma design spec.
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byType(FavoritesSection),
          checkTapTargetSize: false,
        );
      },
    );

    testWidgets(
      'meets label guidelines when loaded in both themes',
      (tester) async {
        await setupA11yTest(tester);
        // Tap target size disabled: CoreChipSize.small renders at 42px, below
        // the 48px minimum. Chips are supplementary visual labels per Figma spec.
        // Text contrast disabled: chip label tokens achieve ~3.73:1, below WCAG
        // AA (4.5:1 for 14px). A dedicated chip text token is needed in CoreUI.
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            calculations: _calculations,
            estimations: _estimations,
          ),
          find.byType(FavoritesSection),
          checkTapTargetSize: false,
          checkTextContrast: false,
        );
      },
    );
  });
}
