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
    Size size = const Size(390, 200),
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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

  group('FavoriteCalculationCard Screenshot Tests - Light', () {
    testWidgets('renders base calculation card correctly', (tester) async {
      const baseSize = Size(390, 200);
      final calculation = FavoriteCalculation(
        id: 'calc-1',
        date: DateTime(2025, 4, 22, 14, 30),
        tags: const ['Flooring', 'Area', 'Tagname'],
      );

      await pumpCalculationCard(tester: tester, calculation: calculation);

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${baseSize.width.toInt()}x${baseSize.height.toInt()}/favorite_calculation_card_base.png',
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
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_at_max.png',
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
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_overflow_plus1.png',
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
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_overflow.png',
        ),
      );
    });
  });

  group('FavoriteCalculationCard Screenshot Tests - Dark', () {
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${baseSize.width.toInt()}x${baseSize.height.toInt()}/favorite_calculation_card_base_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_at_max_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_overflow_plus1_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${size.width.toInt()}x${size.height.toInt()}/favorite_calculation_card_overflow_dark.png',
        ),
      );
    });
  });
}
