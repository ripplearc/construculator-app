import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/testing/testing.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_results_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  group('SearchResultsViews A11y Tests', () {
    final testDate = DateTime(2025, 5, 3, 14, 30);

    CostEstimate makeEstimation({
      String id = 'est-1',
      String estimateName = '2nd Wall Cost',
      double? totalCost = 12343.88,
    }) {
      return CostEstimate.defaultEstimate(
        id: id,
        estimateName: estimateName,
        totalCost: totalCost,
        createdAt: testDate,
        updatedAt: testDate,
      );
    }

    Widget buildList(
      SearchResults results,
      ThemeData theme, {
      void Function(CostEstimate)? onEstimationMenuTap,
      bool hasMore = false,
      bool loadMoreFailed = false,
      VoidCallback? onRetryLoadMore,
    }) {
      return MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SearchResultsList(
            results: results,
            onEstimationTap: (_) {},
            onEstimationMenuTap: onEstimationMenuTap,
            hasMore: hasMore,
            loadMoreFailed: loadMoreFailed,
            onRetryLoadMore: onRetryLoadMore,
            estimationTileProvider: const FakeEstimationTileProvider(),
          ),
        ),
      );
    }

    group('SearchResultsList', () {
      testWidgets('a11y: estimation card tap target passes in both themes', (tester) async {
        await setupA11yTest(tester);

        final results = SearchResults(estimations: [makeEstimation()]);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildList(results, theme, onEstimationMenuTap: (_) {}),
          find.byKey(const ValueKey('estimationCard_est-1')),
        );
      });

      testWidgets('a11y: menu icon tap target passes in both themes', (tester) async {
        await setupA11yTest(tester);

        final results = SearchResults(estimations: [makeEstimation()]);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildList(results, theme, onEstimationMenuTap: (_) {}),
          find.byKey(const Key('menuIcon')),
        );
      });

      testWidgets('a11y: load-more retry button tap target passes in both themes', (tester) async {
        await setupA11yTest(tester);

        final results = SearchResults(estimations: [makeEstimation()]);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildList(
            results,
            theme,
            hasMore: true,
            loadMoreFailed: true,
            onRetryLoadMore: () {},
          ),
          find.byKey(const Key('searchResultsLoadMoreRetryButton')),
        );
      });
    });

    group('SearchResultsEmptyView', () {
      testWidgets('a11y: empty state text contrast passes in both themes', (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => MaterialApp(
            theme: theme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SearchResultsEmptyView(query: 'Wall')),
          ),
          find.byKey(const Key('searchResultsEmptyView')),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      });
    });
  });
}
