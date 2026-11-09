import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_section_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 160);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => loadAppFontsAll());

  Future<void> pumpHeaders(
    WidgetTester tester,
    ThemeData theme, {
    required double materials,
    required double labor,
    required double equipment,
  }) async {
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
        home: Scaffold(
          body: Column(
            children: [
              CostSectionHeader(
                type: CostItemType.material,
                subtotal: materials,
              ),
              CostSectionHeader(type: CostItemType.labor, subtotal: labor),
              CostSectionHeader(
                type: CostItemType.equipment,
                subtotal: equipment,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('Cost section header Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('three empty sections at zero dollars', (tester) async {
      await pumpHeaders(tester, theme, materials: 0, labor: 0, equipment: 0);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/cost_section_header/empty$suffix.png'),
      );
    });

    testWidgets('subtotals up to six figures keep the commas', (tester) async {
      await pumpHeaders(
        tester,
        theme,
        materials: 1265.02,
        labor: 48200.5,
        equipment: 497311.09,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/cost_section_header/filled$suffix.png'),
      );
    });
  });
}
