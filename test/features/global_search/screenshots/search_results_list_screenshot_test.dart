import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/testing/testing.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const Size listSize = Size(390, 400);
  const Size singleCardSize = Size(390, 220);
  const Size emptySize = Size(390, 300);
  const Size loadingSize = Size(390, 300);
  const Size footerSize = Size(390, 300);
  const double ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  CostEstimate makeEstimation({
    String id = 'est-1',
    String estimateName = '2nd Wall Cost',
    double? totalCost = 12343.88,
    DateTime? updatedAt,
  }) {
    final date = updatedAt ?? DateTime(2025, 5, 3, 14, 30);
    return CostEstimate.defaultEstimate(
      id: id,
      estimateName: estimateName,
      totalCost: totalCost,
      createdAt: date,
      updatedAt: date,
    );
  }

  Project makeProject({
    String id = 'project-1',
    String projectName = 'Downtown Office Complex',
  }) {
    final date = DateTime(2025, 5, 3, 14, 30);
    return Project(
      id: id,
      projectName: projectName,
      creatorUserId: 'user-1',
      createdAt: date,
      updatedAt: date,
      status: ProjectStatus.active,
    );
  }

  Future<void> pumpSearchResultsList({
    required WidgetTester tester,
    required Size size,
    required SearchResults results,
    required ThemeData theme,
    bool hasMore = false,
    bool isLoadingMore = false,
    bool loadMoreFailed = false,
    VoidCallback? onRetryLoadMore,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: SearchResultsList(
              results: results,
              onProjectTap: (_) {},
              onEstimationTap: (_) {},
              onEstimationMenuTap: (_) {},
              hasMore: hasMore,
              isLoadingMore: isLoadingMore,
              loadMoreFailed: loadMoreFailed,
              onRetryLoadMore: onRetryLoadMore,
              estimationTileProvider: const FakeEstimationTileProvider(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpEmptyView({
    required WidgetTester tester,
    required Size size,
    required String query,
    required ThemeData theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: SearchResultsEmptyView(query: query),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpLoadingView({
    required WidgetTester tester,
    required Size size,
    required ThemeData theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: const SearchResultsLoadingView(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  screenshotThemeGroups('SearchResultsList Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders two estimation cards correctly', (tester) async {
      final results = SearchResults(
        estimations: [
          makeEstimation(id: 'est-1', estimateName: '2nd Wall Cost', totalCost: 12343.88),
          makeEstimation(
            id: 'est-2',
            estimateName: 'Wall Cost',
            totalCost: 10000.88,
            updatedAt: DateTime(2025, 4, 22, 14, 30),
          ),
        ],
      );

      await pumpSearchResultsList(
        tester: tester,
        size: listSize,
        results: results,
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${listSize.width}x${listSize.height}/two_estimation_cards$suffix.png',
        ),
      );
    });

    testWidgets('renders single estimation card correctly', (tester) async {
      final results = SearchResults(
        estimations: [
          makeEstimation(estimateName: '2nd Wall Cost', totalCost: 12343.88),
        ],
      );

      await pumpSearchResultsList(
        tester: tester,
        size: singleCardSize,
        results: results,
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${singleCardSize.width}x${singleCardSize.height}/single_estimation_card$suffix.png',
        ),
      );
    });

    testWidgets('renders the load-more loading footer correctly', (
      tester,
    ) async {
      final results = SearchResults(
        estimations: [
          makeEstimation(estimateName: '2nd Wall Cost', totalCost: 12343.88),
        ],
      );

      await pumpSearchResultsList(
        tester: tester,
        size: footerSize,
        results: results,
        theme: theme,
        hasMore: true,
        isLoadingMore: true,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${footerSize.width}x${footerSize.height}/load_more_loading_footer$suffix.png',
        ),
      );
    });

    testWidgets('renders the load-more failure footer correctly', (
      tester,
    ) async {
      final results = SearchResults(
        estimations: [
          makeEstimation(estimateName: '2nd Wall Cost', totalCost: 12343.88),
        ],
      );

      await pumpSearchResultsList(
        tester: tester,
        size: footerSize,
        results: results,
        theme: theme,
        hasMore: true,
        loadMoreFailed: true,
        onRetryLoadMore: () {},
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${footerSize.width}x${footerSize.height}/load_more_failure_footer$suffix.png',
        ),
      );
    });

    testWidgets('renders the end-of-results footer correctly', (tester) async {
      final results = SearchResults(
        estimations: [
          makeEstimation(estimateName: '2nd Wall Cost', totalCost: 12343.88),
        ],
      );

      await pumpSearchResultsList(
        tester: tester,
        size: footerSize,
        results: results,
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${footerSize.width}x${footerSize.height}/end_of_results_footer$suffix.png',
        ),
      );
    });

    testWidgets('renders a project card above an estimation card correctly', (
      tester,
    ) async {
      final results = SearchResults(
        projects: [makeProject()],
        estimations: [
          makeEstimation(estimateName: '2nd Wall Cost', totalCost: 12343.88),
        ],
      );

      await pumpSearchResultsList(
        tester: tester,
        size: listSize,
        results: results,
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${listSize.width}x${listSize.height}/project_and_estimation_cards$suffix.png',
        ),
      );
    });
  });

  screenshotThemeGroups('SearchResultsEmptyView Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders empty state correctly', (tester) async {
      await pumpEmptyView(
        tester: tester,
        size: emptySize,
        query: 'Wall',
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${emptySize.width}x${emptySize.height}/empty_state$suffix.png',
        ),
      );
    });
  });

  screenshotThemeGroups('SearchResultsLoadingView Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders loading state correctly', (tester) async {
      await pumpLoadingView(tester: tester, size: loadingSize, theme: theme);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${loadingSize.width}x${loadingSize.height}/loading_state$suffix.png',
        ),
      );
    });
  });
}
