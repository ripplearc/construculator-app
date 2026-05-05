import 'package:construculator/features/estimation/data/estimation_tile_provider_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 140);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Modular.init(_TestAppModule());
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() async {
    await loadAppFontsAll();
  });

  group('CostEstimationTile Screenshot Tests', () {
    Future<void> pumpCostEstimationTile({
      required WidgetTester tester,
      required CostEstimate estimation,
      required VoidCallback onTap,
      VoidCallback? onMenuTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Material(
            child: CostEstimationTile(
              estimation: estimation,
              onTap: onTap,
              onMenuTap: onMenuTap,
              provider: Modular.get<EstimationTileProvider>(),
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
      return CostEstimate.defaultEstimate(
        estimateName: estimateName,
        totalCost: totalCost,
        createdAt: createdAt,
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

class _TestAppModule extends Module {
  static final FakeClockImpl fakeClock = FakeClockImpl();

  @override
  void binds(Injector i) {
    i.addSingleton<Clock>(() => fakeClock);
    i.addLazySingleton<EstimationTileProvider>(
      () => const EstimationTileProviderImpl(),
    );
  }
}
