import 'package:construculator/features/dashboard/presentation/widgets/project_search_recent_search_item.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_recent_searches_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const terms = ['foundation', 'wall'];

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
        body: ProjectSearchRecentSearchesList(
          recentSearches: recentSearches,
          onItemTap: onItemTap ?? (_) {},
          onTrailingTap: onTrailingTap ?? (_) {},
          // Resolves false so the static harness never completes a
          // dismissal — the row data here can never change.
          onItemDismissRequested: onItemDismissRequested ?? (_) async => false,
        ),
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  group('ProjectSearchRecentSearchesList', () {
    testWidgets('renders all items with per-term keys', (tester) async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pump();

      expect(find.byType(ProjectSearchRecentSearchItem), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('recent_search_item_foundation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recent_search_item_wall')),
        findsOneWidget,
      );
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
        find.byKey(const ValueKey('recent_search_item_wall')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(dismissedTerm, 'wall');
    });

    testWidgets('reveals the delete background while swiping', (tester) async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('recent_search_item_wall')),
        const Offset(-100, 0),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('recent_search_delete_icon_wall')),
        findsOneWidget,
        reason: 'only the dragged row may reveal its delete background',
      );
    });
  });
}
