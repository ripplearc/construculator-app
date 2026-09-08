import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_estimation_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 160);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpEstimationCard({
    required WidgetTester tester,
    required FavoriteEstimation estimation,
    required ThemeData theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(
          child: Center(
            child: FavoriteEstimationCard(
              estimation: estimation,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('FavoriteEstimationCard Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders base estimation card correctly', (tester) async {
      final estimation = FavoriteEstimation(
        id: 'est-1',
        title: '2nd Wall cost',
        date: DateTime(2025, 5, 3, 14, 30),
        totalCost: 12343.88,
      );

      await pumpEstimationCard(
        tester: tester,
        estimation: estimation,
        theme: theme,
      );

      await expectLater(
        find.byType(FavoriteEstimationCard),
        matchesGoldenFile(
          'goldens/favorite_estimation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_estimation_card_base$suffix.png',
        ),
      );
    });

    testWidgets('renders estimation card with long title correctly', (
      tester,
    ) async {
      final estimation = FavoriteEstimation(
        id: 'est-2',
        title: 'Complete Home Renovation and Extension Project Phase Two',
        date: DateTime(2025, 4, 22, 14, 30),
        totalCost: 10000.88,
      );

      await pumpEstimationCard(
        tester: tester,
        estimation: estimation,
        theme: theme,
      );

      await expectLater(
        find.byType(FavoriteEstimationCard),
        matchesGoldenFile(
          'goldens/favorite_estimation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_estimation_card_long_title$suffix.png',
        ),
      );
    });
  });
}
