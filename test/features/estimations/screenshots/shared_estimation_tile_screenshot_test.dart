import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 140);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpTile({
    required WidgetTester tester,
    required EstimationTileData data,
    VoidCallback? onMenuTap,
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
          child: SharedEstimationTile(
            data: data,
            onTap: () {},
            onMenuTap: onMenuTap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SharedEstimationTile Screenshot Tests - Light', () {
    testWidgets('renders base tile correctly', (tester) async {
      await pumpTile(
        tester: tester,
        data: _FakeData(
          estimateName: 'Base Estimate',
          totalCost: 50000.0,
          displayDate: DateTime(2024, 1, 1, 8, 30),
        ),
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(SharedEstimationTile),
        matchesGoldenFile(
          'goldens/shared_estimation_tile/${size.width}x${size.height}/shared_estimation_tile_base.png',
        ),
      );
    });

    testWidgets('renders tile with long name correctly', (tester) async {
      await pumpTile(
        tester: tester,
        data: _FakeData(
          estimateName: 'Complete Home Renovation and Extension Project',
          totalCost: 125000.75,
          displayDate: DateTime(2024, 3, 10, 16, 45),
        ),
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(SharedEstimationTile),
        matchesGoldenFile(
          'goldens/shared_estimation_tile/${size.width}x${size.height}/shared_estimation_tile_long_name.png',
        ),
      );
    });

    testWidgets('renders tile without menu tap (menu icon excluded from a11y)', (tester) async {
      await pumpTile(
        tester: tester,
        data: _FakeData(
          estimateName: 'Read-Only Estimate',
          totalCost: 8500.0,
          displayDate: DateTime(2024, 2, 14, 12, 0),
        ),
        onMenuTap: null,
      );

      await expectLater(
        find.byType(SharedEstimationTile),
        matchesGoldenFile(
          'goldens/shared_estimation_tile/${size.width}x${size.height}/shared_estimation_tile_no_menu.png',
        ),
      );
    });

    testWidgets('renders tile with null cost showing dash', (tester) async {
      await pumpTile(
        tester: tester,
        data: _FakeData(
          estimateName: 'Pending Estimate',
          totalCost: null,
          displayDate: DateTime(2024, 7, 4, 9, 0),
        ),
        onMenuTap: () {},
      );

      await expectLater(
        find.byType(SharedEstimationTile),
        matchesGoldenFile(
          'goldens/shared_estimation_tile/${size.width}x${size.height}/shared_estimation_tile_no_cost.png',
        ),
      );
    });
  });

  group('SharedEstimationTile Screenshot Tests - Dark', () {
    testWidgets('renders base tile correctly', (tester) async {
      await pumpTile(
        tester: tester,
        data: _FakeData(
          estimateName: 'Base Estimate',
          totalCost: 50000.0,
          displayDate: DateTime(2024, 1, 1, 8, 30),
        ),
        onMenuTap: () {},
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(SharedEstimationTile),
        matchesGoldenFile(
          'goldens/shared_estimation_tile/${size.width}x${size.height}/shared_estimation_tile_base_dark.png',
        ),
      );
    });

    testWidgets('renders tile with long name correctly', (tester) async {
      await pumpTile(
        tester: tester,
        data: _FakeData(
          estimateName: 'Complete Home Renovation and Extension Project',
          totalCost: 125000.75,
          displayDate: DateTime(2024, 3, 10, 16, 45),
        ),
        onMenuTap: () {},
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(SharedEstimationTile),
        matchesGoldenFile(
          'goldens/shared_estimation_tile/${size.width}x${size.height}/shared_estimation_tile_long_name_dark.png',
        ),
      );
    });

    testWidgets('renders tile without menu tap (menu icon excluded from a11y)', (tester) async {
      await pumpTile(
        tester: tester,
        data: _FakeData(
          estimateName: 'Read-Only Estimate',
          totalCost: 8500.0,
          displayDate: DateTime(2024, 2, 14, 12, 0),
        ),
        onMenuTap: null,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(SharedEstimationTile),
        matchesGoldenFile(
          'goldens/shared_estimation_tile/${size.width}x${size.height}/shared_estimation_tile_no_menu_dark.png',
        ),
      );
    });

    testWidgets('renders tile with null cost showing dash', (tester) async {
      await pumpTile(
        tester: tester,
        data: _FakeData(
          estimateName: 'Pending Estimate',
          totalCost: null,
          displayDate: DateTime(2024, 7, 4, 9, 0),
        ),
        onMenuTap: () {},
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(SharedEstimationTile),
        matchesGoldenFile(
          'goldens/shared_estimation_tile/${size.width}x${size.height}/shared_estimation_tile_no_cost_dark.png',
        ),
      );
    });
  });
}

class _FakeData implements EstimationTileData {
  @override
  final String estimateName;

  @override
  final double? totalCost;

  @override
  final DateTime displayDate;

  const _FakeData({
    required this.estimateName,
    required this.displayDate,
    this.totalCost,
  });
}
