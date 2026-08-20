import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/testing/testing.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

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
      bool isLoadingMore = false,
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
            onProjectTap: (_) {},
            onEstimationTap: (_) {},
            onEstimationMenuTap: onEstimationMenuTap,
            hasMore: hasMore,
            isLoadingMore: isLoadingMore,
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

      testWidgets('a11y: project card tap target passes in both themes', (tester) async {
        await setupA11yTest(tester);

        final results = SearchResults(
          projects: [
            Project(
              id: 'p1',
              projectName: 'Downtown Office Complex',
              creatorUserId: 'user-1',
              createdAt: testDate,
              updatedAt: testDate,
              status: ProjectStatus.active,
            ),
          ],
        );

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildList(results, theme),
          find.byKey(const ValueKey('projectCard_p1')),
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

      testWidgets('a11y: end-of-results caption contrast passes in both themes',
          (tester) async {
        await setupA11yTest(tester);

        final results = SearchResults(estimations: [makeEstimation()]);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => buildList(results, theme),
          find.byKey(const Key('searchResultsNoMoreResultsMessage')),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      });

      testWidgets('a11y: the loading footer announces the caption once, not '
          'the spinner\'s generic label too', (tester) async {
        await setupA11yTest(tester);

        final results = SearchResults(estimations: [makeEstimation()]);

        for (final theme in [CoreTheme.light(), CoreTheme.dark()]) {
          await tester.pumpWidget(
            buildList(results, theme, hasMore: true, isLoadingMore: true),
          );

          final handle = tester.ensureSemantics();
          // Counting every loading-ish label, rather than asserting the
          // indicator's exact wording is absent, keeps this failing if CoreUI
          // renames its label instead of silently passing.
          final announced = find
              .bySemanticsLabel(RegExp('loading', caseSensitive: false))
              .evaluate()
              .length;
          expect(
            announced,
            1,
            reason:
                'the indicator\'s own label would double-announce the caption '
                'below it',
          );
          expect(
            find.bySemanticsLabel('Loading more results'),
            findsOneWidget,
          );
          handle.dispose();
        }
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
