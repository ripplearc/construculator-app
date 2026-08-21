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
    Future<bool> Function(String)? onItemDismissRequested,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      home: Scaffold(
        body: GlobalSearchRecentSearchesList(
          recentSearches: recentSearches,
          onItemTap: onItemTap ?? (_) {},
          onTrailingTap: onTrailingTap ?? (_) {},
          // Resolves false so the static harness never completes a
          // dismissal — the row data here can never change.
          onItemDismissRequested:
              onItemDismissRequested ?? (_) async => false,
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
      await tester.pump();

      expect(find.byType(GlobalSearchRecentSearchItem), findsNWidgets(2));
      expect(find.text('Material of building'), findsOneWidget);
      expect(find.text('MD bungalow'), findsOneWidget);
    });

    testWidgets('renders correct number of items', (tester) async {
      await tester.pumpWidget(makeTestableWidget(recentSearches: ['a', 'b', 'c']));
      await tester.pump();

      expect(find.byType(GlobalSearchRecentSearchItem), findsNWidgets(3));
    });

    testWidgets('onItemTap called with correct term', (tester) async {
      String? tappedTerm;
      await tester.pumpWidget(
        makeTestableWidget(onItemTap: (t) => tappedTerm = t),
      );
      await tester.pump();

      await tester.tap(find.text('Material of building'));
      await tester.pump();

      expect(tappedTerm, 'Material of building');
    });

    testWidgets('onTrailingTap called with correct term', (tester) async {
      String? tappedTerm;
      await tester.pumpWidget(
        makeTestableWidget(onTrailingTap: (t) => tappedTerm = t),
      );
      await tester.pump();

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
      await tester.pump();

      expect(
        find.byKey(const ValueKey('recent_search_item_Material of building')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recent_search_item_MD bungalow')),
        findsOneWidget,
      );
    });

    testWidgets('asserts when recentSearches is empty', (tester) async {
      await tester.pumpWidget(makeTestableWidget(recentSearches: const []));
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('swiping a row end-to-start requests dismissal with the '
        'term', (tester) async {
      String? dismissedTerm;
      await tester.pumpWidget(
        makeTestableWidget(
          onItemDismissRequested: (t) async {
            dismissedTerm = t;
            // False keeps the row mounted: the static harness holds no
            // bloc to remove it from the list data.
            return false;
          },
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('recent_search_item_MD bungalow')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(dismissedTerm, 'MD bungalow');
    });

    testWidgets('reveals the delete background while swiping', (tester) async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('recent_search_item_MD bungalow')),
        const Offset(-100, 0),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('recent_search_delete_icon_MD bungalow')),
        findsOneWidget,
        reason: 'only the dragged row may reveal its delete background',
      );
    });
  });
}
