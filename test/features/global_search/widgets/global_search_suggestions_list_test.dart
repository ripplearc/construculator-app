import 'package:construculator/features/global_search/presentation/widgets/global_search_suggestion_item.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_suggestions_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const suggestions = ['Carpentry', 'Carparking cost'];

  Widget makeTestableWidget({
    List<String> items = suggestions,
    String query = 'Car',
    ValueChanged<String>? onItemTap,
    ValueChanged<String>? onTrailingTap,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      home: Scaffold(
        body: GlobalSearchSuggestionsList(
          suggestions: items,
          query: query,
          onItemTap: onItemTap ?? (_) {},
          onTrailingTap: onTrailingTap ?? (_) {},
        ),
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  group('GlobalSearchSuggestionsList', () {
    testWidgets('renders all items', (tester) async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pump();

      expect(find.byType(GlobalSearchSuggestionItem), findsNWidgets(2));
      expect(find.text('Carpentry'), findsOneWidget);
      expect(find.text('Carparking cost'), findsOneWidget);
    });

    testWidgets('renders correct number of items', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(items: const ['a', 'b', 'c', 'd']),
      );
      await tester.pump();

      expect(find.byType(GlobalSearchSuggestionItem), findsNWidgets(4));
    });

    testWidgets('onItemTap called with correct term', (tester) async {
      String? tappedTerm;
      await tester.pumpWidget(
        makeTestableWidget(onItemTap: (t) => tappedTerm = t),
      );
      await tester.pump();

      await tester.tap(find.text('Carpentry'));
      await tester.pump();

      expect(tappedTerm, 'Carpentry');
    });

    testWidgets('onTrailingTap called with correct term', (tester) async {
      String? tappedTerm;
      await tester.pumpWidget(
        makeTestableWidget(onTrailingTap: (t) => tappedTerm = t),
      );
      await tester.pump();

      await tester.tap(
        find.bySemanticsLabel('Fill search field with Carpentry'),
      );
      await tester.pump();

      expect(tappedTerm, 'Carpentry');
    });

    testWidgets('each item has a unique ValueKey based on its term', (
      tester,
    ) async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pump();

      expect(
        find.byKey(const ValueKey('suggestion_item_Carpentry')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('suggestion_item_Carparking cost')),
        findsOneWidget,
      );
    });

  });
}
