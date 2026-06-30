import 'package:construculator/features/global_search/presentation/widgets/global_search_suggestion_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  BuildContext? buildContext;

  Widget makeTestableWidget({
    String term = 'Carpentry',
    String query = 'Car',
    VoidCallback? onTap,
    VoidCallback? onTrailingTap,
  }) {
    return MaterialApp(
      theme: createTestTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            buildContext = context;
            return GlobalSearchSuggestionItem(
              term: term,
              query: query,
              onTap: onTap ?? () {},
              onTrailingTap: onTrailingTap ?? () {},
            );
          },
        ),
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  group('GlobalSearchSuggestionItem', () {
    testWidgets('renders the suggestion term', (tester) async {
      await tester.pumpWidget(makeTestableWidget());
      await tester.pump();

      expect(find.text('Carpentry'), findsOneWidget);
    });

    testWidgets('onTap is called when row body is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(makeTestableWidget(onTap: () => tapped = true));
      await tester.pump();

      await tester.tap(find.text('Carpentry'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onTrailingTap is called via localized semantic label',
        (tester) async {
      var trailingTapped = false;
      await tester.pumpWidget(
        makeTestableWidget(onTrailingTap: () => trailingTapped = true),
      );
      await tester.pump();

      await tester.tap(
        find.bySemanticsLabel(l10n().globalSearchSuggestionFillSemanticLabel('Carpentry')),
      );
      await tester.pump();

      expect(trailingTapped, isTrue);
    });

    testWidgets('trailing semantic label includes the term', (tester) async {
      await tester.pumpWidget(makeTestableWidget(term: 'Plumbing', query: 'Pl'));
      await tester.pump();

      expect(
        find.bySemanticsLabel(
          l10n().globalSearchSuggestionFillSemanticLabel('Plumbing'),
        ),
        findsOneWidget,
      );
    });
  });
}
