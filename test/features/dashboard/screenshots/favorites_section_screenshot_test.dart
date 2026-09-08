import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/features/dashboard/domain/entities/favourite_filter_type.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorites_section.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favourite_sort_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 500);
  const ratio = 1.0;

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpFavoritesSection({
    required WidgetTester tester,
    required ThemeData theme,
    List<FavoriteCalculation> calculations = const [],
    List<FavoriteEstimation> estimations = const [],
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
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FavoritesSection(
                calculations: calculations,
                estimations: estimations,
                onViewAll: () {},
                onCalculationTap: (_) {},
                onEstimationTap: (_) {},
                onFilterChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpBottomSheet({
    required WidgetTester tester,
    required ThemeData theme,
    FavouriteFilterType selectedFilter = FavouriteFilterType.all,
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
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: FavouriteSortBottomSheet(
              selectedFilter: selectedFilter,
              onFilterSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('FavoritesSection Screenshot Tests', (theme, suffix) {
    testWidgets('renders loaded section with calculations and estimations', (
      tester,
    ) async {
      final date = DateTime(2025, 4, 22, 14, 30);
      await pumpFavoritesSection(
        tester: tester,
        theme: theme,
        calculations: [
          FavoriteCalculation(
            id: 'c1',
            date: date,
            tags: const ['Flooring', 'Area', 'Tagname', 'Tagname'],
          ),
          FavoriteCalculation(
            id: 'c2',
            date: DateTime(2025, 4, 22, 14, 30),
            tags: const ['Tagname', 'Tagname', 'Tagname'],
          ),
        ],
        estimations: [
          FavoriteEstimation(
            id: 'e1',
            title: '2nd Wall cost',
            date: DateTime(2025, 5, 3, 14, 30),
            totalCost: 12343.88,
          ),
          FavoriteEstimation(
            id: 'e2',
            title: 'Wall cost',
            date: date,
            totalCost: 10000.88,
          ),
        ],
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/favorites_section/${size.width.toInt()}x${size.height.toInt()}/favorites_section_loaded$suffix.png',
        ),
      );
    });

    testWidgets('renders empty state correctly', (tester) async {
      await pumpFavoritesSection(tester: tester, theme: theme);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/favorites_section/${size.width.toInt()}x${size.height.toInt()}/favorites_section_empty$suffix.png',
        ),
      );
    });
  });

  screenshotThemeGroups('FavouriteSortBottomSheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders sort sheet with All selected', (tester) async {
      await pumpBottomSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/favorites_section/${size.width.toInt()}x${size.height.toInt()}/favourite_sort_sheet_all$suffix.png',
        ),
      );
    });

    testWidgets('renders sort sheet with Cost estimations selected', (
      tester,
    ) async {
      await pumpBottomSheet(
        tester: tester,
        theme: theme,
        selectedFilter: FavouriteFilterType.costEstimations,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/favorites_section/${size.width.toInt()}x${size.height.toInt()}/favourite_sort_sheet_cost_estimations$suffix.png',
        ),
      );
    });

    testWidgets('renders sort sheet with Calculations selected', (
      tester,
    ) async {
      await pumpBottomSheet(
        tester: tester,
        theme: theme,
        selectedFilter: FavouriteFilterType.calculations,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/favorites_section/${size.width.toInt()}x${size.height.toInt()}/favourite_sort_sheet_calculations$suffix.png',
        ),
      );
    });
  });
}
