import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/testing/testing.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const Size listSize = Size(390, 400);
  const Size singleCardSize = Size(390, 220);
  const Size emptySize = Size(390, 300);
  const Size loadingSize = Size(390, 300);
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

  Future<void> pumpSearchResultsList({
    required WidgetTester tester,
    required Size size,
    required SearchResults results,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: SearchResultsList(
              results: results,
              onEstimationTap: (_) {},
              onEstimationMenuTap: (_) {},
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
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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

  group('SearchResultsList Screenshot Tests - Light', () {
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

      await pumpSearchResultsList(tester: tester, size: listSize, results: results);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${listSize.width}x${listSize.height}/two_estimation_cards.png',
        ),
      );
    });

    testWidgets('renders single estimation card correctly', (tester) async {
      final results = SearchResults(
        estimations: [
          makeEstimation(estimateName: '2nd Wall Cost', totalCost: 12343.88),
        ],
      );

      await pumpSearchResultsList(tester: tester, size: singleCardSize, results: results);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${singleCardSize.width}x${singleCardSize.height}/single_estimation_card.png',
        ),
      );
    });
  });

  group('SearchResultsEmptyView Screenshot Tests - Light', () {
    testWidgets('renders empty state correctly', (tester) async {
      await pumpEmptyView(tester: tester, size: emptySize, query: 'Wall');

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${emptySize.width}x${emptySize.height}/empty_state.png',
        ),
      );
    });
  });

  group('SearchResultsLoadingView Screenshot Tests - Light', () {
    testWidgets('renders loading state correctly', (tester) async {
      await pumpLoadingView(tester: tester, size: loadingSize);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${loadingSize.width}x${loadingSize.height}/loading_state.png',
        ),
      );
    });
  });

  group('SearchResultsList Screenshot Tests - Dark', () {
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${listSize.width}x${listSize.height}/two_estimation_cards_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${singleCardSize.width}x${singleCardSize.height}/single_estimation_card_dark.png',
        ),
      );
    });
  });

  group('SearchResultsEmptyView Screenshot Tests - Dark', () {
    testWidgets('renders empty state correctly', (tester) async {
      await pumpEmptyView(
        tester: tester,
        size: emptySize,
        query: 'Wall',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${emptySize.width}x${emptySize.height}/empty_state_dark.png',
        ),
      );
    });
  });

  group('SearchResultsLoadingView Screenshot Tests - Dark', () {
    testWidgets('renders loading state correctly', (tester) async {
      await pumpLoadingView(
        tester: tester,
        size: loadingSize,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/search_results_list/${loadingSize.width}x${loadingSize.height}/loading_state_dark.png',
        ),
      );
    });
  });
}
