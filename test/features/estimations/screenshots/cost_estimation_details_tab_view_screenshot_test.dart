import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_details_tab_view.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  Future<void> pumpTabView({
    required WidgetTester tester,
    int selectedTab = 0,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: const CostEstimationDetailsTabView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (selectedTab == 1) {
      await tester.ensureVisible(find.text(l10n.laboursTab));
      await tester.tap(find.text(l10n.laboursTab));
      await tester.pumpAndSettle();
    } else if (selectedTab == 2) {
      await tester.ensureVisible(find.text(l10n.equipmentsTab));
      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
    }
  }

  setUp(() async {
    l10n = lookupAppLocalizations(const Locale('en'));
    await loadAppFontsAll();
  });

  group('CostEstimationDetailsTabView Screenshot Tests - Light', () {
    testWidgets('renders materials tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpTabView(tester: tester, selectedTab: 0);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/materials_tab.png',
        ),
      );
    });

    testWidgets('renders labours tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpTabView(tester: tester, selectedTab: 1);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/labours_tab.png',
        ),
      );
    });

    testWidgets('renders equipments tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpTabView(tester: tester, selectedTab: 2);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/equipments_tab.png',
        ),
      );
    });
  });

  group('CostEstimationDetailsTabView Screenshot Tests - Dark', () {
    testWidgets('renders materials tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpTabView(tester: tester, selectedTab: 0, theme: createTestThemeDark());

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/materials_tab_dark.png',
        ),
      );
    });

    testWidgets('renders labours tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpTabView(tester: tester, selectedTab: 1, theme: createTestThemeDark());

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/labours_tab_dark.png',
        ),
      );
    });

    testWidgets('renders equipments tab correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpTabView(tester: tester, selectedTab: 2, theme: createTestThemeDark());

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_details_tab_view/${size.width}x${size.height}/equipments_tab_dark.png',
        ),
      );
    });
  });
}
