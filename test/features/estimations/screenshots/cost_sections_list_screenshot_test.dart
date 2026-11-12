import 'package:construculator/features/estimation/presentation/bloc/cost_items_bloc/cost_items_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_sections_list.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';
import '../helpers/cost_line_test_items.dart';

void main() {
  const size = Size(412, 900);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => loadAppFontsAll());

  Future<void> pumpList(
    WidgetTester tester,
    ThemeData theme,
    CostItemsLoaded costs, {
    String? highlightedItemId,
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
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: sheetSurface(context),
            body: CostSectionsList(
              costs: costs,
              highlightedItemId: highlightedItemId,
              onLineTap: (_) {},
              onAddFirstCost: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('Cost sections list Screenshot Tests', (theme, suffix) {
    testWidgets('an empty estimate shows examples and the first-cost button', (
      tester,
    ) async {
      await pumpList(
        tester,
        theme,
        const CostItemsLoaded(
          items: [],
          materialsSubtotal: 0,
          laborSubtotal: 0,
          equipmentSubtotal: 0,
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/cost_sections_list/empty$suffix.png'),
      );
    });

    testWidgets('one line per section', (tester) async {
      await pumpList(
        tester,
        theme,
        CostItemsLoaded(
          items: [materialLine(), laborLine(), equipmentLine()],
          materialsSubtotal: 211.34,
          laborSubtotal: 480,
          equipmentSubtotal: 665,
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/cost_sections_list/one_per_section$suffix.png',
        ),
      );
    });

    testWidgets('an empty section shows its placeholder between full ones', (
      tester,
    ) async {
      await pumpList(
        tester,
        theme,
        CostItemsLoaded(
          items: [materialLine(), equipmentLine()],
          materialsSubtotal: 211.34,
          laborSubtotal: 0,
          equipmentSubtotal: 665,
        ),
        highlightedItemId: 'q1',
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/cost_sections_list/empty_labor_with_highlight$suffix.png',
        ),
      );
    });

    testWidgets('a long list with long names and six-figure amounts', (
      tester,
    ) async {
      await pumpList(
        tester,
        theme,
        CostItemsLoaded(
          items: [
            for (var i = 0; i < 4; i++)
              materialLine(
                id: 'm$i',
                name:
                    'Engineered hardwood flooring, wide plank, site finished '
                    'and sealed, lot $i',
                total: 123456.78,
                quantity: 1234.5,
              ),
            for (var i = 0; i < 3; i++)
              laborLine(
                id: 'l$i',
                name: 'Framing crew, shift $i',
                total: 98765.43,
              ),
            for (var i = 0; i < 4; i++)
              equipmentLine(
                id: 'q$i',
                name: 'Telescopic boom lift, 80 ft reach, unit $i',
                total: 345678.9,
              ),
          ],
          materialsSubtotal: 493827.12,
          laborSubtotal: 296296.29,
          equipmentSubtotal: 1382715.6,
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/cost_sections_list/long_list$suffix.png'),
      );
    });
  });
}
