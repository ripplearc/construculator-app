import 'package:construculator/features/dashboard/presentation/widgets/estimation_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 200);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  group('EstimationCard Screenshot Tests', () {
    Future<void> pumpEstimationCard({
      required WidgetTester tester,
      required CostEstimate estimation,
      required VoidCallback onTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Material(
            child: Center(
              child: EstimationCard(estimation: estimation, onTap: onTap),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders base estimation card correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Base Estimate',
        updatedAt: DateTime(2024, 1, 1, 8, 30),
        createdAt: DateTime(2024, 1, 1, 8, 30),
      );

      await pumpEstimationCard(
        tester: tester,
        estimation: estimation,
        onTap: () {},
      );

      await expectLater(
        find.byType(EstimationCard),
        matchesGoldenFile(
          'goldens/estimation_card/${size.width}x${size.height}/estimation_card_base.png',
        ),
      );
    });

    testWidgets('renders estimation card with long name correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Complete Home Renovation and Extension Project',
        updatedAt: DateTime(2024, 3, 10, 16, 45),
        createdAt: DateTime(2024, 3, 10, 16, 45),
      );

      await pumpEstimationCard(
        tester: tester,
        estimation: estimation,
        onTap: () {},
      );

      await expectLater(
        find.byType(EstimationCard),
        matchesGoldenFile(
          'goldens/estimation_card/${size.width}x${size.height}/estimation_card_long_name.png',
        ),
      );
    });
  });
}
