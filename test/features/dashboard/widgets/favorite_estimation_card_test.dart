import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_estimation_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  final date = DateTime(2025, 5, 3, 14, 30);

  FavoriteEstimation buildEstimation({
    String id = 'est-1',
    String title = '2nd Wall cost',
    DateTime? dateOverride,
    double totalCost = 12343.88,
  }) {
    return FavoriteEstimation(
      id: id,
      title: title,
      date: dateOverride ?? date,
      totalCost: totalCost,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required FavoriteEstimation estimation,
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
            child: FavoriteEstimationCard(
              estimation: estimation,
              onTap: onTap,
              onMoreOptions: onMoreOptions,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('displays estimation title', (tester) async {
    await pumpCard(
      tester,
      estimation: buildEstimation(),
      onTap: () {},
    );

    expect(find.text('2nd Wall cost'), findsOneWidget);
  });

  testWidgets('displays formatted total cost', (tester) async {
    await pumpCard(
      tester,
      estimation: buildEstimation(totalCost: 12343.88),
      onTap: () {},
    );

    expect(find.text('\$12,343.88'), findsOneWidget);
  });

  testWidgets('displays formatted date and time', (tester) async {
    await pumpCard(
      tester,
      estimation: buildEstimation(),
      onTap: () {},
    );

    expect(find.text('May 3, 2025 · 2:30 pm'), findsOneWidget);
  });

  testWidgets('invokes onTap when the card is tapped', (tester) async {
    var tapped = false;
    await pumpCard(
      tester,
      estimation: buildEstimation(),
      onTap: () => tapped = true,
    );

    await tester.tap(find.byType(FavoriteEstimationCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onMoreOptions when the more-options icon is tapped', (
    tester,
  ) async {
    var moreOptionsTapped = false;
    await pumpCard(
      tester,
      estimation: buildEstimation(),
      onTap: () {},
      onMoreOptions: () => moreOptionsTapped = true,
    );

    await tester.tap(find.byKey(const Key('estimation_more_options')));
    await tester.pump();

    expect(moreOptionsTapped, isTrue);
  });

  testWidgets('truncates long title with ellipsis', (tester) async {
    tester.view.physicalSize = const Size(390, 160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpCard(
      tester,
      estimation: buildEstimation(
        title: 'Very Long Estimation Title That Should Be Truncated With Ellipsis',
      ),
      onTap: () {},
    );

    final textWidget = tester.widget<Text>(
      find.text(
        'Very Long Estimation Title That Should Be Truncated With Ellipsis',
      ),
    );
    expect(textWidget.maxLines, 1);
    expect(textWidget.overflow, TextOverflow.ellipsis);
  });
}
