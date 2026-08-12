import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_calculation_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpCalculationCard({
    required WidgetTester tester,
    required FavoriteCalculation calculation,
    required ThemeData theme,
    Size size = const Size(390, 200),
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
            child: FavoriteCalculationCard(
              calculation: calculation,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('FavoriteCalculationCard Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders base calculation card correctly', (tester) async {
      const baseSize = Size(390, 200);
      final calculation = FavoriteCalculation(
        id: 'calc-1',
        date: DateTime(2025, 4, 22, 14, 30),
        tags: const ['Flooring', 'Area', 'Tagname'],
      );

      await pumpCalculationCard(
        tester: tester,
        calculation: calculation,
        theme: theme,
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${baseSize.width.toInt()}x${baseSize.height.toInt()}/favorite_calculation_card_base$suffix.png',
        ),
      );
    });

    testWidgets('renders no overflow chip when tags equal maximum', (
      tester,
    ) async {
      const size = Size(390, 200);
      final calculation = FavoriteCalculation(
        id: 'calc-2',
        date: DateTime(2025, 4, 22, 14, 30),
        tags: const [
          'Flooring',
          'Area',
          'Tagname',
          'Roofing',
          'Walls',
          'Ceiling',
          'Paint',
        ],
      );

      await pumpCalculationCard(
        tester: tester,
        calculation: calculation,
        size: size,
        theme: theme,
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_at_max$suffix.png',
        ),
      );
    });

    testWidgets('renders overflow chip with count 1 when one tag exceeds maximum', (
      tester,
    ) async {
      const size = Size(390, 200);
      final calculation = FavoriteCalculation(
        id: 'calc-3',
        date: DateTime(2025, 4, 22, 14, 30),
        tags: const [
          'Flooring',
          'Area',
          'Tagname',
          'Roofing',
          'Walls',
          'Ceiling',
          'Paint',
          'Extra',
        ],
      );

      await pumpCalculationCard(
        tester: tester,
        calculation: calculation,
        size: size,
        theme: theme,
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_overflow_plus1$suffix.png',
        ),
      );
    });

    testWidgets('renders overflow chip when tags exceed maximum', (
      tester,
    ) async {
      const size = Size(390, 200);
      final calculation = FavoriteCalculation(
        id: 'calc-4',
        date: DateTime(2025, 4, 22, 14, 30),
        tags: const [
          'Flooring',
          'Area',
          'Tagname',
          'Roofing',
          'Walls',
          'Ceiling',
          'Paint',
          'Doors',
          'Windows',
          'Insulation',
          'Fixtures',
          'Plumbing',
        ],
      );

      await pumpCalculationCard(
        tester: tester,
        calculation: calculation,
        size: size,
        theme: theme,
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_overflow$suffix.png',
        ),
      );
    });
  });
}
