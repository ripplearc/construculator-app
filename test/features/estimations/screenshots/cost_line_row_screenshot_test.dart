import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_line_row.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';
import '../helpers/cost_line_test_items.dart';

void main() {
  const size = Size(412, 460);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => loadAppFontsAll());

  Future<void> pumpRows(WidgetTester tester, ThemeData theme) async {
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
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: sheetSurface(context),
            body: Padding(
              padding: const EdgeInsets.all(CoreSpacing.space4),
              child: Column(
                spacing: CoreSpacing.space3,
                children: [
                  CostLineRow(item: materialLine(), isHighlighted: false),
                  CostLineRow(item: laborLine(), isHighlighted: false),
                  CostLineRow(item: equipmentLine(), isHighlighted: false),
                  CostLineRow(
                    item: equipmentLine(
                      method: EquipmentPricingMethod.job,
                      duration: null,
                      dailyRate: null,
                      jobAmount: const Money(amount: 400),
                      deliveryFee: null,
                    ),
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('Cost line row Screenshot Tests', (theme, suffix) {
    testWidgets('material, labor, day and job lines, one highlighted', (
      tester,
    ) async {
      await pumpRows(tester, theme);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/cost_line_row/lines$suffix.png'),
      );
    });
  });
}
