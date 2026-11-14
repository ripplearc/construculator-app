import 'package:construculator/features/estimation/presentation/widgets/add_cost_bottom_bar.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

Widget _page(Widget bottomBar) => Builder(
  builder: (context) => Scaffold(
    backgroundColor: sheetSurface(context),
    body: const SizedBox.expand(),
    bottomNavigationBar: bottomBar,
  ),
);

void main() {
  const size = Size(412, 420);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => loadAppFontsAll());

  Future<void> pumpApp(
    WidgetTester tester,
    ThemeData theme,
    Widget home,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('Add cost bottom bar Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('the bar with a six-figure estimate total', (tester) async {
      await pumpApp(
        tester,
        theme,
        _page(
          AddCostBottomBar(
            total: 497311.09,
            isEstimateEmpty: false,
            onAddCost: () {},
            onPreview: () {},
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/add_cost_bottom_bar/with_total$suffix.png'),
      );
    });

    testWidgets('the bar of an empty estimate has no + Add cost', (
      tester,
    ) async {
      await pumpApp(
        tester,
        theme,
        _page(
          AddCostBottomBar(total: 0, isEstimateEmpty: true, onAddCost: () {}),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/add_cost_bottom_bar/empty_estimate$suffix.png',
        ),
      );
    });
  });
}
