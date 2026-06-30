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

  group('FavoriteCalculationCard Screenshot Tests', () {
    Future<void> pumpCalculationCard({
      required WidgetTester tester,
      required FavoriteCalculation calculation,
      Size size = const Size(390, 200),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
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

    testWidgets('renders calculation card with many tags correctly', (
      tester,
    ) async {
      const manyTagsSize = Size(390, 280);
      final calculation = FavoriteCalculation(
        id: 'calc-2',
        date: DateTime(2025, 4, 22, 14, 30),
        tags: const [
          'Flooring',
          'Area',
          'Tagname',
          'Tagname',
          'Tagname',
          'Tagname',
          'Tagname',
        ],
      );

      await pumpCalculationCard(
        tester: tester,
        calculation: calculation,
        size: manyTagsSize,
      );

      await expectLater(
        find.byType(FavoriteCalculationCard),
        matchesGoldenFile(
          'goldens/favorite_calculation_card/${manyTagsSize.width.toInt()}x${manyTagsSize.height.toInt()}/favorite_calculation_card_many_tags.png',
        ),
      );
    });
  });
}
