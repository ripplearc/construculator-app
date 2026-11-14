import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_items_bloc/cost_items_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_sections_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../helpers/cost_line_test_items.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  var firstCostTaps = 0;
  final tappedLines = <String>[];

  setUp(() {
    firstCostTaps = 0;
    tappedLines.clear();
  });

  CostItemsLoaded loaded(List<CostItem> items) => CostItemsLoaded(
    items: items,
    materialsSubtotal: 100,
    laborSubtotal: 200,
    equipmentSubtotal: 300,
  );

  Widget app(CostItemsLoaded costs, {String? highlightedItemId}) => MaterialApp(
    theme: CoreTheme.light(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CostSectionsList(
        costs: costs,
        highlightedItemId: highlightedItemId,
        onLineTap: (line) => tappedLines.add(line.id),
        onAddFirstCost: () => firstCostTaps++,
      ),
    ),
  );

  double top(WidgetTester tester, String key) =>
      tester.getTopLeft(find.byKey(Key(key))).dy;

  testWidgets('shows the three sections in a fixed order with subtotals', (
    tester,
  ) async {
    await tester.pumpWidget(app(loaded([equipmentLine(), materialLine()])));

    expect(
      top(tester, 'cost_section_header_material'),
      lessThan(top(tester, 'cost_section_header_labor')),
    );
    expect(
      top(tester, 'cost_section_header_labor'),
      lessThan(top(tester, 'cost_section_header_equipment')),
    );
    for (final entry in {
      'material': r'$100.00',
      'labor': r'$200.00',
      'equipment': r'$300.00',
    }.entries) {
      expect(
        tester
            .widget<Text>(find.byKey(Key('cost_section_subtotal_${entry.key}')))
            .data,
        entry.value,
      );
    }
  });

  testWidgets('puts each line in its own section', (tester) async {
    await tester.pumpWidget(
      app(loaded([equipmentLine(id: 'q1'), materialLine(id: 'm1')])),
    );

    expect(
      top(tester, 'cost_line_m1'),
      lessThan(top(tester, 'cost_section_header_labor')),
    );
    expect(
      top(tester, 'cost_line_q1'),
      greaterThan(top(tester, 'cost_section_header_equipment')),
    );
  });

  testWidgets('puts a labor line under the Labor header', (tester) async {
    await tester.pumpWidget(
      app(loaded([laborLine(id: 'l1'), equipmentLine(id: 'q1')])),
    );

    expect(
      top(tester, 'cost_line_l1'),
      greaterThan(top(tester, 'cost_section_header_labor')),
    );
    expect(
      top(tester, 'cost_line_l1'),
      lessThan(top(tester, 'cost_section_header_equipment')),
    );
  });

  testWidgets('scrolls the section headers away with the list', (tester) async {
    await tester.pumpWidget(
      app(
        loaded([
          materialLine(id: 'm1'),
          for (var i = 0; i < 30; i++) equipmentLine(id: 'q$i'),
        ]),
      ),
    );
    final before = top(tester, 'cost_section_header_material');

    await tester.drag(
      find.byKey(const Key('cost_sections_list')),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getTopLeft(find.byKey(const Key('cost_section_header_material')))
          .dy,
      lessThan(before),
    );
  });

  testWidgets('keeps an empty section in place with its placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(app(loaded([materialLine()])));

    expect(find.byKey(const Key('cost_section_header_labor')), findsOneWidget);
    expect(
      find.byKey(const Key('cost_section_header_equipment')),
      findsOneWidget,
    );
    expect(
      find.byKey(CostSectionsList.emptySectionKey(CostItemType.labor)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(
              CostSectionsList.emptySectionKey(CostItemType.equipment),
            ),
          )
          .data,
      'No equipment costs yet',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(CostSectionsList.emptySectionKey(CostItemType.labor)),
          )
          .data,
      l10n.costSectionEmptyLabor,
    );
    expect(
      find.byKey(CostSectionsList.emptySectionKey(CostItemType.material)),
      findsNothing,
    );
    for (final type in CostItemType.values) {
      expect(find.byKey(CostSectionsList.examplesKey(type)), findsNothing);
    }
    expect(find.byKey(CostSectionsList.addFirstCostButtonKey), findsNothing);
    expect(find.byKey(CostSectionsList.emptyEstimateTitleKey), findsNothing);
  });

  testWidgets(
    'shows the Materials placeholder when only other sections have lines',
    (tester) async {
      await tester.pumpWidget(app(loaded([laborLine()])));

      expect(find.text(l10n.costSectionEmptyMaterial), findsOneWidget);
      expect(find.text(l10n.costSectionEmptyLabor), findsNothing);
    },
  );

  testWidgets(
    'shows no section placeholder while the whole estimate is empty',
    (tester) async {
      await tester.pumpWidget(app(loaded(const [])));

      for (final type in CostItemType.values) {
        expect(
          find.byKey(CostSectionsList.emptySectionKey(type)),
          findsNothing,
        );
      }
    },
  );

  testWidgets('puts 12 dp above the first card and between cards, 28 below', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(loaded([materialLine(id: 'm1'), materialLine(id: 'm2')])),
    );

    final header = tester.getBottomLeft(
      find.byKey(const Key('cost_section_header_material')),
    );
    final first = tester.getRect(find.byKey(const Key('cost_line_frame_m1')));
    final second = tester.getRect(find.byKey(const Key('cost_line_frame_m2')));
    final next = tester.getTopLeft(
      find.byKey(const Key('cost_section_header_labor')),
    );
    expect(first.top - header.dy, CoreSpacing.space3);
    expect(second.top - first.bottom, CoreSpacing.space3);
    expect(next.dy - second.bottom, CoreSpacing.space7);
  });

  testWidgets(
    'shows examples and the first-cost button when everything is empty',
    (tester) async {
      await tester.pumpWidget(app(loaded(const [])));

      expect(find.text(l10n.costSectionExamplesMaterial), findsOneWidget);
      expect(find.text(l10n.costSectionExamplesLabor), findsOneWidget);
      expect(find.text(l10n.costSectionExamplesEquipment), findsOneWidget);
      expect(find.text(l10n.emptyEstimateTitle), findsOneWidget);
      expect(find.text(l10n.emptyEstimateBody), findsOneWidget);

      await tester.tap(find.byKey(CostSectionsList.addFirstCostButtonKey));

      expect(firstCostTaps, 1);
    },
  );

  testWidgets('reports which line was tapped', (tester) async {
    await tester.pumpWidget(app(loaded([materialLine(id: 'm7')])));

    await tester.tap(find.byKey(const Key('cost_line_m7')));

    expect(tappedLines, ['m7']);
  });

  testWidgets('fills only the line just added with the highlight colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        loaded([materialLine(id: 'm1'), materialLine(id: 'm2')]),
        highlightedItemId: 'm2',
      ),
    );
    Color? fillOf(String id) {
      final frame = find.byKey(Key('cost_line_frame_$id'));
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: frame, matching: find.byType(DecoratedBox)),
      );
      return (box.decoration as BoxDecoration).color;
    }

    final colors = AppColorsExtension.of(
      tester.element(find.byKey(const Key('cost_line_frame_m2'))),
    );
    expect(fillOf('m2'), colors.backgroundBlueLight);
    expect(fillOf('m1'), colors.buttonInverse);
  });
}
