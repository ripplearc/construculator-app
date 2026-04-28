import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_details_tab_view.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 844);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpTabView({
    required WidgetTester tester,
    int selectedTab = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CostEstimationDetailsTabView()),
      ),
    );
    await tester.pumpAndSettle();

    if (selectedTab == 1) {
      await tester.tap(find.text('Labours'));
      await tester.pumpAndSettle();
    } else if (selectedTab == 2) {
      await tester.tap(find.text('Equipments'));
      await tester.pumpAndSettle();
    }
  }

  setUp(() async {
    await loadAppFontsAll();
  });

  group('CostEstimationDetailsTabView Screenshot Tests', () {
    testWidgets('renders materials tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpTabView(tester: tester, selectedTab: 0);

      await expectLater(
        find.byType(CostEstimationDetailsTabView),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/materials_tab.png',
        ),
      );
    });

    testWidgets('renders labours tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpTabView(tester: tester, selectedTab: 1);

      await expectLater(
        find.byType(CostEstimationDetailsTabView),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/labours_tab.png',
        ),
      );
    });

    testWidgets('renders equipments tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpTabView(tester: tester, selectedTab: 2);

      await expectLater(
        find.byType(CostEstimationDetailsTabView),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/equipments_tab.png',
        ),
      );
    });
  });
}
