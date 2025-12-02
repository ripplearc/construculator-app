import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../font_loader.dart';

void main() {
  final size = const Size(390, 120);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('CostEstimationTile Screenshot Tests', () {
    Future<void> pumpCostEstimationTile({
      required WidgetTester tester,
      required CostEstimate estimation,
      VoidCallback? onTap,
      VoidCallback? onMenuTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Material(
            child: CostEstimationTile(
              estimation: estimation,
              onTap: onTap,
              onMenuTap: onMenuTap,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    CostEstimate createTestEstimation({
      required String estimateName,
      double? totalCost,
      required DateTime createdAt,
    }) {
      return CostEstimate(
        id: 'test-id-123',
        projectId: 'project-456',
        estimateName: estimateName,
        estimateDescription: 'Test description',
        creatorUserId: 'user-789',
        markupConfiguration: MarkupConfiguration(
          overallType: MarkupType.overall,
          overallValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 10.0,
          ),
        ),
        totalCost: totalCost,
        lockStatus: const UnlockedStatus(),
        createdAt: createdAt,
        updatedAt: DateTime(2024, 1, 15, 14, 30),
      );
    }

    testWidgets('renders base cost estimation tile correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final estimation = createTestEstimation(
        estimateName: 'Base Estimate',
        totalCost: 50000.0,
        createdAt: DateTime(2024, 1, 1, 8, 30),
      );

      await pumpCostEstimationTile(
        tester: tester,
        estimation: estimation,
        onTap: () {},
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(CostEstimationTile),
        matchesGoldenFile(
          'goldens/cost_estimation_tile/${size.width}x${size.height}/cost_estimation_tile_base.png',
        ),
      );
    });

    testWidgets('renders cost estimation tile with long name correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final estimation = createTestEstimation(
        estimateName: 'Complete Home Renovation and Extension Project',
        totalCost: 125000.75,
        createdAt: DateTime(2024, 3, 10, 16, 45),
      );

      await pumpCostEstimationTile(
        tester: tester,
        estimation: estimation,
        onTap: () {},
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(CostEstimationTile),
        matchesGoldenFile(
          'goldens/cost_estimation_tile/${size.width}x${size.height}/cost_estimation_tile_long_name.png',
        ),
      );
    });
  });
}
