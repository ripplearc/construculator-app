import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_calculation_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  final date = DateTime(2025, 4, 22, 14, 30);

  FavoriteCalculation buildCalculation({
    String id = 'calc-1',
    DateTime? dateOverride,
    List<String> tags = const ['Flooring', 'Area', 'Tagname'],
  }) {
    return FavoriteCalculation(
      id: id,
      date: dateOverride ?? date,
      tags: tags,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required FavoriteCalculation calculation,
    required VoidCallback onTap,
    VoidCallback? onMoreOptions,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: FavoriteCalculationCard(
              calculation: calculation,
              onTap: onTap,
              onMoreOptions: onMoreOptions,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('displays formatted date and time', (tester) async {
    await pumpCard(
      tester,
      calculation: buildCalculation(),
      onTap: () {},
    );

    expect(find.text('apr 22, 2025 · 2:30 pm'), findsOneWidget);
  });

  testWidgets('renders all tags as CoreChip widgets', (tester) async {
    final tags = ['Flooring', 'Area', 'Tagname'];
    await pumpCard(
      tester,
      calculation: buildCalculation(tags: tags),
      onTap: () {},
    );

    expect(find.byType(CoreChip), findsNWidgets(tags.length));
    for (final tag in tags) {
      expect(find.text(tag), findsOneWidget);
    }
  });

  testWidgets('invokes onTap when the card is tapped', (tester) async {
    var tapped = false;
    await pumpCard(
      tester,
      calculation: buildCalculation(),
      onTap: () => tapped = true,
    );

    await tester.tap(find.byType(FavoriteCalculationCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onMoreOptions when the more-options icon is tapped', (
    tester,
  ) async {
    var moreOptionsTapped = false;
    await pumpCard(
      tester,
      calculation: buildCalculation(),
      onTap: () {},
      onMoreOptions: () => moreOptionsTapped = true,
    );

    await tester.tap(find.byKey(const Key('calculation_more_options')));
    await tester.pump();

    expect(moreOptionsTapped, isTrue);
  });
}
