import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/presentation/widgets/estimation_card_widget.dart';
import 'package:construculator/features/global_search/presentation/widgets/search_results_views.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/testing/testing.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/search_results_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  final testDate = DateTime(2025, 5, 3, 14, 30);

  CostEstimate makeEstimation({
    String id = 'est-1',
    String estimateName = '2nd Wall Cost',
    double? totalCost = 12343.88,
    DateTime? updatedAt,
  }) {
    return CostEstimate.defaultEstimate(
      id: id,
      estimateName: estimateName,
      totalCost: totalCost,
      createdAt: testDate,
      updatedAt: updatedAt ?? testDate,
    );
  }

  Widget createWidget({
    required SearchResults results,
    void Function(CostEstimate)? onEstimationTap,
    void Function(CostEstimate)? onEstimationMenuTap,
    bool hasMore = false,
    bool isLoadingMore = false,
    bool loadMoreFailed = false,
    VoidCallback? onLoadMore,
    VoidCallback? onRetryLoadMore,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SearchResultsList(
          results: results,
          onEstimationTap: onEstimationTap ?? (_) {},
          onEstimationMenuTap: onEstimationMenuTap,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          loadMoreFailed: loadMoreFailed,
          onLoadMore: onLoadMore,
          onRetryLoadMore: onRetryLoadMore,
          estimationTileProvider: const FakeEstimationTileProvider(),
        ),
      ),
    );
  }

  // Enough estimations to overflow the default test viewport, so the list
  // can actually be scrolled toward its end.
  List<CostEstimate> makeScrollablePage({int count = 20}) {
    return List.generate(
      count,
      (i) => makeEstimation(id: 'est-$i', estimateName: 'Estimation $i'),
    );
  }

  Widget createEmptyView({String query = 'Wall'}) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SearchResultsEmptyView(query: query)),
    );
  }

  Widget createLoadingView() {
    return MaterialApp(
      theme: CoreTheme.light(),
      home: const Scaffold(body: SearchResultsLoadingView()),
    );
  }

  group('SearchResultsList', () {
    group('Section header', () {
      testWidgets('renders "Most relevant" section header', (tester) async {
        await tester.pumpWidget(
          createWidget(results: const SearchResults()),
        );

        expect(find.byKey(const Key('mostRelevantHeader')), findsOneWidget);
        expect(find.text('Most relevant'), findsOneWidget);
      });
    });

    group('Estimation cards', () {
      testWidgets('renders one EstimationCard per estimation', (tester) async {
        final results = SearchResults(
          estimations: [
            makeEstimation(id: 'est-1', estimateName: '2nd Wall Cost'),
            makeEstimation(id: 'est-2', estimateName: 'Wall Cost'),
          ],
        );
        await tester.pumpWidget(createWidget(results: results));

        expect(find.byKey(const ValueKey('estimationCard_est-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('estimationCard_est-2')), findsOneWidget);
        expect(find.text('2nd Wall Cost'), findsOneWidget);
        expect(find.text('Wall Cost'), findsOneWidget);
      });

      testWidgets('renders nothing when estimations list is empty', (tester) async {
        await tester.pumpWidget(
          createWidget(results: const SearchResults()),
        );

        expect(find.byType(EstimationCard), findsNothing);
      });

      testWidgets('renders single estimation card', (tester) async {
        final results = SearchResults(
          estimations: [makeEstimation()],
        );
        await tester.pumpWidget(createWidget(results: results));

        expect(find.byKey(const ValueKey('estimationCard_est-1')), findsOneWidget);
      });
    });

    group('Tap callbacks', () {
      testWidgets('calls onEstimationTap with correct estimation when card is tapped', (tester) async {
        CostEstimate? tapped;
        final estimation = makeEstimation(estimateName: '2nd Wall Cost');
        final results = SearchResults(estimations: [estimation]);

        await tester.pumpWidget(
          createWidget(
            results: results,
            onEstimationTap: (e) => tapped = e,
          ),
        );

        await tester.tap(find.text('2nd Wall Cost'));
        await tester.pump();

        expect(tapped, equals(estimation));
      });

      testWidgets('calls onEstimationMenuTap with correct estimation when menu is tapped', (tester) async {
        CostEstimate? menuTapped;
        final estimation = makeEstimation(estimateName: 'Wall Cost');
        final results = SearchResults(estimations: [estimation]);

        await tester.pumpWidget(
          createWidget(
            results: results,
            onEstimationMenuTap: (e) => menuTapped = e,
          ),
        );

        await tester.tap(find.byKey(const Key('menuIcon')));
        await tester.pump();

        expect(menuTapped, equals(estimation));
      });

      testWidgets('renders menu icon without tap semantics when onEstimationMenuTap is null', (tester) async {
        final results = SearchResults(estimations: [makeEstimation()]);
        await tester.pumpWidget(
          createWidget(results: results, onEstimationMenuTap: null),
        );

        expect(find.byKey(const Key('menuIcon')), findsOneWidget);
        // EstimationCard wraps the menu icon in a GestureDetector (not an
        // IconButton), so we locate the closest GestureDetector ancestor and
        // verify its onTap is null when no menu callback is provided.
        final gesture = tester.widget<GestureDetector>(
          find
              .ancestor(
                of: find.byKey(const Key('menuIcon')),
                matching: find.byType(GestureDetector),
              )
              .first,
        );
        expect(gesture.onTap, isNull);
      });

      testWidgets('calls correct estimation tap when multiple cards exist', (tester) async {
        final tappedIds = <String>[];
        final est1 = makeEstimation(id: 'est-1', estimateName: 'First');
        final est2 = makeEstimation(id: 'est-2', estimateName: 'Second');
        final results = SearchResults(estimations: [est1, est2]);

        await tester.pumpWidget(
          createWidget(
            results: results,
            onEstimationTap: (e) => tappedIds.add(e.id),
          ),
        );

        await tester.tap(find.text('Second'));
        await tester.pump();

        expect(tappedIds, ['est-2']);
      });
    });

    group('ListView', () {
      testWidgets('renders the scrollable list container', (tester) async {
        await tester.pumpWidget(
          createWidget(results: const SearchResults()),
        );

        expect(find.byKey(const Key('searchResultsListView')), findsOneWidget);
      });
    });

    group('Infinite scroll', () {
      testWidgets('invokes onLoadMore when scrolled near the end and more '
          'results exist', (tester) async {
        var loadMoreCalls = 0;
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage()),
            hasMore: true,
            onLoadMore: () => loadMoreCalls += 1,
          ),
        );

        await tester.drag(
          find.byKey(const Key('searchResultsListView')),
          const Offset(0, -5000),
        );
        await tester.pump();

        expect(loadMoreCalls, greaterThan(0));
      });

      testWidgets('ignores scroll notifications bubbling up from a nested '
          'scrollable', (tester) async {
        var loadMoreCalls = 0;
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage()),
            hasMore: true,
            onLoadMore: () => loadMoreCalls += 1,
          ),
        );

        final listContext = tester.element(
          find.byKey(const Key('searchResultsListView')),
        );
        // The notification is constructed rather than produced by a real
        // nested scrollable: SearchResultsList builds its own rows, so no
        // inner Scrollable can be injected through its public API. Dispatching
        // from the list's own element leaves `depth` exactly as set here, so
        // the two cases below differ in nothing but that field.
        //
        // Metrics of an inner list sitting at its own end: acted on, they
        // would request a page for a list that has not been scrolled at all.
        final nestedMetrics = FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: 0,
          pixels: 0,
          viewportDimension: 100,
          axisDirection: AxisDirection.down,
          devicePixelRatio: tester.view.devicePixelRatio,
        );

        ScrollUpdateNotification(
          metrics: nestedMetrics,
          context: listContext,
          depth: 1,
        ).dispatch(listContext);
        await tester.pump();

        expect(
          loadMoreCalls,
          0,
          reason: 'a nested scrollable may not request this list\'s pages',
        );

        // The same metrics at depth 0 do request a page, so the depth — not
        // the metrics — is what rejected the notification above.
        ScrollUpdateNotification(
          metrics: nestedMetrics,
          context: listContext,
          depth: 0,
        ).dispatch(listContext);
        await tester.pump();

        expect(loadMoreCalls, 1);
      });

      testWidgets('does not invoke onLoadMore when no more results exist',
          (tester) async {
        var loadMoreCalls = 0;
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage()),
            hasMore: false,
            onLoadMore: () => loadMoreCalls += 1,
          ),
        );

        await tester.drag(
          find.byKey(const Key('searchResultsListView')),
          const Offset(0, -5000),
        );
        await tester.pump();

        expect(loadMoreCalls, 0);
      });

      testWidgets('does not invoke onLoadMore while the last page fetch is '
          'in flight', (tester) async {
        var loadMoreCalls = 0;
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage()),
            hasMore: true,
            isLoadingMore: true,
            onLoadMore: () => loadMoreCalls += 1,
          ),
        );

        await tester.drag(
          find.byKey(const Key('searchResultsListView')),
          const Offset(0, -5000),
        );
        await tester.pump();

        expect(loadMoreCalls, 0);
      });

      testWidgets('does not invoke onLoadMore on scroll after a failed page '
          'fetch — only the retry affordance may re-request', (tester) async {
        var loadMoreCalls = 0;
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage()),
            hasMore: true,
            loadMoreFailed: true,
            onLoadMore: () => loadMoreCalls += 1,
          ),
        );

        await tester.drag(
          find.byKey(const Key('searchResultsListView')),
          const Offset(0, -5000),
        );
        await tester.pump();

        expect(loadMoreCalls, 0);
      });

      testWidgets('renders the loading footer while a page fetch is in flight',
          (tester) async {
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage()),
            hasMore: true,
            isLoadingMore: true,
          ),
        );

        await tester.drag(
          find.byKey(const Key('searchResultsListView')),
          const Offset(0, -5000),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('searchResultsLoadMoreIndicator')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('searchResultsLoadMoreFailedMessage')),
          findsNothing,
        );
      });

      testWidgets('renders the failure footer with a retry affordance that '
          'invokes onRetryLoadMore', (tester) async {
        var retryCalls = 0;
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage()),
            hasMore: true,
            loadMoreFailed: true,
            onRetryLoadMore: () => retryCalls += 1,
          ),
        );

        await tester.drag(
          find.byKey(const Key('searchResultsListView')),
          const Offset(0, -5000),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('searchResultsLoadMoreFailedMessage')),
          findsOneWidget,
        );
        expect(find.text("Couldn't load more results"), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('searchResultsLoadMoreRetryButton')),
        );
        await tester.pump();

        expect(retryCalls, 1);
      });

      testWidgets('renders no footer when idle and more results may exist',
          (tester) async {
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage(count: 2)),
            hasMore: true,
          ),
        );

        expect(
          find.byKey(const Key('searchResultsLoadMoreIndicator')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('searchResultsLoadMoreFailedMessage')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('searchResultsEndOfResultsMessage')),
          findsNothing,
        );
      });

      testWidgets('captions the loading footer so the spinner is not the only '
          'signal', (tester) async {
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage(count: 2)),
            hasMore: true,
            isLoadingMore: true,
          ),
        );

        expect(
          find.byKey(const Key('searchResultsLoadMoreLoadingMessage')),
          findsOneWidget,
        );
        expect(find.text('Loading more results'), findsOneWidget);
      });

      testWidgets('closes the list off with the end-of-results footer once '
          'every page is loaded', (tester) async {
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage(count: 2)),
            hasMore: false,
          ),
        );

        expect(
          find.byKey(const Key('searchResultsEndOfResultsMessage')),
          findsOneWidget,
        );
        expect(find.text('No more results'), findsOneWidget);
        expect(
          find.byKey(const Key('searchResultsEndOfResultsDivider')),
          findsOneWidget,
        );
      });

      testWidgets('renders no end-of-results footer while a page fetch is in '
          'flight', (tester) async {
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage(count: 2)),
            hasMore: false,
            isLoadingMore: true,
          ),
        );

        expect(
          find.byKey(const Key('searchResultsEndOfResultsMessage')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('searchResultsLoadMoreIndicator')),
          findsOneWidget,
        );
      });

      testWidgets('renders no end-of-results footer while the failure footer '
          'owns the end of the list', (tester) async {
        await tester.pumpWidget(
          createWidget(
            results: SearchResults(estimations: makeScrollablePage(count: 2)),
            hasMore: false,
            loadMoreFailed: true,
            onRetryLoadMore: () {},
          ),
        );

        expect(
          find.byKey(const Key('searchResultsEndOfResultsMessage')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('searchResultsLoadMoreFailedMessage')),
          findsOneWidget,
        );
      });
    });
  });

  group('SearchResultsLoadingView', () {
    testWidgets('renders loading view container', (tester) async {
      await tester.pumpWidget(createLoadingView());

      expect(find.byKey(const Key('searchResultsLoadingView')), findsOneWidget);
    });

    testWidgets('renders CoreLoadingIndicator', (tester) async {
      await tester.pumpWidget(createLoadingView());

      expect(find.byKey(const Key('loadingIndicator')), findsOneWidget);
    });
  });

  group('SearchResultsEmptyView', () {
    testWidgets('renders empty view container', (tester) async {
      await tester.pumpWidget(createEmptyView());

      expect(find.byKey(const Key('searchResultsEmptyView')), findsOneWidget);
    });

    testWidgets('renders search icon', (tester) async {
      await tester.pumpWidget(createEmptyView());

      expect(find.byKey(const Key('emptySearchIcon')), findsOneWidget);
    });

    testWidgets('renders empty message containing the query', (tester) async {
      await tester.pumpWidget(createEmptyView(query: 'Wall'));

      expect(find.byKey(const Key('emptySearchMessage')), findsOneWidget);
      expect(find.textContaining('Wall'), findsOneWidget);
    });

    testWidgets('renders message with different queries', (tester) async {
      await tester.pumpWidget(createEmptyView(query: 'Roof renovation'));

      expect(find.textContaining('Roof renovation'), findsOneWidget);
    });

    testWidgets('does not throw for empty query string', (tester) async {
      await tester.pumpWidget(createEmptyView(query: ''));

      expect(tester.takeException(), isNull);
    });
  });
}
