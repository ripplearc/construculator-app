import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/global_search/presentation/widgets/estimation_card_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const Size baseSize = Size(390, 140);
  const Size withOwnerSize = Size(390, 170);
  const Size tallSize = Size(390, 165);
  const double ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpEstimationCard({
    required WidgetTester tester,
    required Size size,
    required CostEstimate estimation,
    String? ownerName,
    VoidCallback? onMenuTap,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(
          child: EstimationCard(
            estimation: estimation,
            ownerName: ownerName,
            onTap: () {},
            onMenuTap: onMenuTap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('EstimationCard Screenshot Tests', () {
    testWidgets('renders base card without owner correctly', (tester) async {
      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Kitchen Renovation',
        totalCost: 50000.0,
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 0),
      );

      await pumpEstimationCard(
        tester: tester,
        size: baseSize,
        estimation: estimation,
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(EstimationCard),
        matchesGoldenFile(
          'goldens/estimation_card_widget/${baseSize.width}x${baseSize.height}/estimation_card_base.png',
        ),
      );
    });

    testWidgets('renders card with owner name correctly', (tester) async {
      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Office Fit-Out',
        totalCost: 120000.0,
        createdAt: DateTime(2024, 9, 3, 14, 30),
        updatedAt: DateTime(2024, 9, 3, 14, 30),
      );

      await pumpEstimationCard(
        tester: tester,
        size: withOwnerSize,
        estimation: estimation,
        ownerName: 'Jane Smith',
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(EstimationCard),
        matchesGoldenFile(
          'goldens/estimation_card_widget/${withOwnerSize.width}x${withOwnerSize.height}/estimation_card_with_owner.png',
        ),
      );
    });

    testWidgets('renders card with long estimate name correctly', (tester) async {
      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Complete Home Renovation and Extension Project Phase 2',
        totalCost: 250000.75,
        createdAt: DateTime(2024, 11, 20, 8, 0),
        updatedAt: DateTime(2024, 11, 20, 8, 0),
      );

      await pumpEstimationCard(
        tester: tester,
        size: tallSize,
        estimation: estimation,
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(EstimationCard),
        matchesGoldenFile(
          'goldens/estimation_card_widget/${tallSize.width}x${tallSize.height}/estimation_card_long_name.png',
        ),
      );
    });

    testWidgets('renders card with null totalCost showing dash', (tester) async {
      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Pending Estimate',
        totalCost: null,
        createdAt: DateTime(2024, 1, 1, 9, 0),
        updatedAt: DateTime(2024, 1, 1, 9, 0),
      );

      await pumpEstimationCard(
        tester: tester,
        size: baseSize,
        estimation: estimation,
      );

      await expectLater(
        find.byType(EstimationCard),
        matchesGoldenFile(
          'goldens/estimation_card_widget/${baseSize.width}x${baseSize.height}/estimation_card_no_cost.png',
        ),
      );
    });

    testWidgets('renders card with long owner name truncated', (tester) async {
      final estimation = CostEstimate.defaultEstimate(
        estimateName: 'Site Survey',
        totalCost: 3500.0,
        createdAt: DateTime(2024, 5, 5, 16, 0),
        updatedAt: DateTime(2024, 5, 5, 16, 0),
      );

      await pumpEstimationCard(
        tester: tester,
        size: withOwnerSize,
        estimation: estimation,
        ownerName: 'Mr. Alexander Von Humboldt-Richardson Jr.',
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(EstimationCard),
        matchesGoldenFile(
          'goldens/estimation_card_widget/${withOwnerSize.width}x${withOwnerSize.height}/estimation_card_long_owner.png',
        ),
      );
    });
  });
}
