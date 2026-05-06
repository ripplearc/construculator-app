import 'package:construculator/features/global_search/presentation/widgets/global_search_recent_search_item.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_recent_searches_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const terms = ['Material of building', 'MD bungalow'];

  Widget makeTestableWidget({
    List<String> recentSearches = terms,
    ValueChanged<String>? onItemTap,
    ValueChanged<String>? onTrailingTap,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      home: Scaffold(
        body: GlobalSearchRecentSearchesList(
          recentSearches: recentSearches,
          onItemTap: onItemTap ?? (_) {},
          onTrailingTap: onTrailingTap ?? (_) {},
        ),
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  group('GlobalSearchRecentSearchesList', () {
    testWidgets('renders all items', (tester) async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(GlobalSearchRecentSearchItem), findsNWidgets(2));
      expect(find.text('Material of building'), findsOneWidget);
      expect(find.text('MD bungalow'), findsOneWidget);
    });

    testWidgets('renders correct number of items', (tester) async {
      await tester.pumpWidget(makeTestableWidget(recentSearches: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalSearchRecentSearchItem), findsNWidgets(3));
    });

    testWidgets('onItemTap called with correct term', (tester) async {
      String? tappedTerm;
      await tester.pumpWidget(
        makeTestableWidget(onItemTap: (t) => tappedTerm = t),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Material of building'));
      await tester.pump();

      expect(tappedTerm, 'Material of building');
    });

    testWidgets('onTrailingTap called with correct term', (tester) async {
      String? tappedTerm;
      await tester.pumpWidget(
        makeTestableWidget(onTrailingTap: (t) => tappedTerm = t),
      );
      await tester.pumpAndSettle();

      // Tap via the accessible semantic label we own rather than a key internal
      // to CoreSearchRowItem — avoids coupling to the package's implementation.
      await tester.tap(
        find.bySemanticsLabel('Fill search field with Material of building'),
      );
      await tester.pump();

      expect(tappedTerm, 'Material of building');
    });

    testWidgets('each item has a unique ValueKey based on its term', (tester) async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('recent_search_item_Material of building')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recent_search_item_MD bungalow')),
        findsOneWidget,
      );
    });

    testWidgets('empty list renders nothing', (tester) async {
      // The widget asserts non-empty in debug mode; this test documents that
      // an empty list produces zero GlobalSearchRecentSearchItem widgets in
      // a release build (callers must guard before rendering this widget).
      await tester.pumpWidget(
        makeTestableWidget(recentSearches: const []),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlobalSearchRecentSearchItem), findsNothing);
    });
  });
}
