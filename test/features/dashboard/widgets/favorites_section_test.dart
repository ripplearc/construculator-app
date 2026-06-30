import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_calculation_card.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_estimation_card.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorites_section.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  final date = DateTime(2025, 4, 22, 14, 30);

  FavoriteCalculation makeCalculation(String id) => FavoriteCalculation(
        id: id,
        date: date,
        tags: const ['Flooring', 'Area'],
      );

  FavoriteEstimation makeEstimation(String id, String title) =>
      FavoriteEstimation(
        id: id,
        title: title,
        date: date,
        totalCost: 10000.00,
      );

  Future<void> pumpSection(
    WidgetTester tester, {
    List<FavoriteCalculation> calculations = const [],
    List<FavoriteEstimation> estimations = const [],
    VoidCallback? onViewAll,
    void Function(String id)? onCalculationTap,
    void Function(String id)? onEstimationTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FavoritesSection(
            calculations: calculations,
            estimations: estimations,
            onViewAll: onViewAll ?? () {},
            onCalculationTap: onCalculationTap ?? (_) {},
            onEstimationTap: onEstimationTap ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders section title', (tester) async {
    await pumpSection(tester);
    expect(find.text('Favourites'), findsOneWidget);
  });

  testWidgets('renders view all button', (tester) async {
    await pumpSection(tester);
    expect(find.text('View all'), findsOneWidget);
  });

  testWidgets('shows empty state when both lists are empty', (tester) async {
    await pumpSection(tester);
    expect(find.text('No favourites yet.'), findsOneWidget);
    expect(find.byType(FavoriteCalculationCard), findsNothing);
    expect(find.byType(FavoriteEstimationCard), findsNothing);
  });

  testWidgets('renders FavoriteCalculationCard for each calculation', (
    tester,
  ) async {
    await pumpSection(
      tester,
      calculations: [makeCalculation('c1'), makeCalculation('c2')],
    );

    expect(find.byType(FavoriteCalculationCard), findsNWidgets(2));
    expect(find.byType(FavoriteEstimationCard), findsNothing);
  });

  testWidgets('renders FavoriteEstimationCard for each estimation', (
    tester,
  ) async {
    await pumpSection(
      tester,
      estimations: [
        makeEstimation('e1', 'Wall cost'),
        makeEstimation('e2', 'Floor cost'),
      ],
    );

    expect(find.byType(FavoriteEstimationCard), findsNWidgets(2));
    expect(find.byType(FavoriteCalculationCard), findsNothing);
    expect(find.text('Wall cost'), findsOneWidget);
    expect(find.text('Floor cost'), findsOneWidget);
  });

  testWidgets('renders both calculation and estimation cards together', (
    tester,
  ) async {
    await pumpSection(
      tester,
      calculations: [makeCalculation('c1')],
      estimations: [makeEstimation('e1', 'Wall cost')],
    );

    expect(find.byType(FavoriteCalculationCard), findsOneWidget);
    expect(find.byType(FavoriteEstimationCard), findsOneWidget);
  });

  testWidgets('invokes onViewAll when view all button is tapped', (
    tester,
  ) async {
    var viewAllTapped = false;
    await pumpSection(tester, onViewAll: () => viewAllTapped = true);

    await tester.tap(find.text('View all'));
    await tester.pump();

    expect(viewAllTapped, isTrue);
  });

  testWidgets('invokes onCalculationTap with correct id when card is tapped', (
    tester,
  ) async {
    String? tappedId;
    await pumpSection(
      tester,
      calculations: [makeCalculation('calc-42')],
      onCalculationTap: (id) => tappedId = id,
    );

    await tester.tap(find.byType(FavoriteCalculationCard));
    await tester.pump();

    expect(tappedId, 'calc-42');
  });

  testWidgets('invokes onEstimationTap with correct id when card is tapped', (
    tester,
  ) async {
    String? tappedId;
    await pumpSection(
      tester,
      estimations: [makeEstimation('est-99', 'Roof cost')],
      onEstimationTap: (id) => tappedId = id,
    );

    await tester.tap(find.byType(FavoriteEstimationCard));
    await tester.pump();

    expect(tappedId, 'est-99');
  });
}
