import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/material_unit_list.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/widgets/select_unit_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Unit? picked;

  setUp(() => picked = null);

  Future<void> openSheet(
    WidgetTester tester, {
    Unit? selected,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: GestureDetector(
                key: const Key('open_sheet'),
                onTap: () async => picked = await CoreQuickSheet.show<Unit>(
                  context: context,
                  child: SelectUnitSheet(
                    groups: imperialMaterialUnits,
                    selected: selected,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the six group headings in capitals', (tester) async {
    await openSheet(tester);

    for (final heading in [
      'BY LENGTH',
      'BY AREA',
      'BY VOLUME',
      'BY WEIGHT',
      'BY COUNT',
      'BY PACKAGING',
    ]) {
      expect(find.text(heading), findsOneWidget);
    }
  });

  testWidgets('reads the group headings to a screen reader as headings', (
    tester,
  ) async {
    await openSheet(tester);

    expect(
      tester.getSemantics(find.text('BY LENGTH')),
      isSemantics(isHeader: true, label: 'BY LENGTH'),
    );
  });

  testWidgets('shows each unit in its own row with its symbol and name', (
    tester,
  ) async {
    await openSheet(tester);
    final l10n = lookupAppLocalizations(const Locale('en'));

    final units = [for (final group in imperialMaterialUnits) ...group.units];
    expect(units, hasLength(23));
    for (final unit in units) {
      final row = find.byKey(Key('unit_option_${unit.name}'));
      for (final text in [unit.symbol(l10n), unit.displayName(l10n)]) {
        expect(
          find.descendant(of: row, matching: find.text(text)),
          findsOneWidget,
          reason: '${unit.name} row shows "$text"',
        );
      }
    }
  });

  testWidgets('opens with nothing selected when no unit is given', (
    tester,
  ) async {
    await openSheet(tester);

    expect(
      tester.getSemantics(find.byKey(const Key('unit_option_feet'))),
      isSemantics(isChecked: false, isInMutuallyExclusiveGroup: true),
    );
  });

  testWidgets('opens with nothing selected for a saved unit not in the list', (
    tester,
  ) async {
    await openSheet(tester, selected: Unit.liters);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('unit_option_liters')), findsNothing);
    for (final group in imperialMaterialUnits) {
      for (final unit in group.units) {
        expect(
          tester.getSemantics(find.byKey(Key('unit_option_${unit.name}'))),
          isSemantics(isChecked: false),
          reason: '${unit.name} is not checked',
        );
      }
    }
  });

  testWidgets('opens scrolled to a selected unit near the end', (tester) async {
    await openSheet(tester, selected: Unit.tubes);

    final row = tester.getRect(find.byKey(const Key('unit_option_tubes')));
    expect(row.top, greaterThan(0));
    expect(row.bottom, lessThanOrEqualTo(917));
    expect(
      tester.getSemantics(find.byKey(const Key('unit_option_tubes'))),
      isSemantics(isChecked: true, label: 'tb, Tube'),
    );
  });

  testWidgets(
    'opens with a selected unit mid-list in the middle of the sheet',
    (tester) async {
      await openSheet(tester, selected: Unit.pounds);

      final listTop = tester.getRect(find.byType(SheetHeader)).bottom;
      final listBottom = tester.getRect(find.byType(SelectUnitSheet)).bottom;
      final row = tester.getRect(find.byKey(const Key('unit_option_pounds')));
      expect(
        row.center.dy,
        moreOrLessEquals((listTop + listBottom) / 2, epsilon: 0.5),
      );
    },
  );

  testWidgets('closes with the unit tapped', (tester) async {
    await openSheet(tester, selected: Unit.feet);

    await tester.ensureVisible(find.byKey(const Key('unit_option_pounds')));
    await tester.tap(find.byKey(const Key('unit_option_pounds')));
    await tester.pumpAndSettle();

    expect(picked, Unit.pounds);
    expect(find.text('Select unit'), findsNothing);
  });

  testWidgets('closes with no unit from the back arrow', (tester) async {
    await openSheet(tester, selected: Unit.feet);

    await tester.tap(find.byKey(const Key('sheet_back_button')));
    await tester.pumpAndSettle();

    expect(picked, isNull);
    expect(find.text('Select unit'), findsNothing);
  });

  bool isFocusInRow(String unitName) {
    final focused = FocusManager.instance.primaryFocus!.context!;
    return find
        .ancestor(
          of: find.byElementPredicate((element) => element == focused),
          matching: find.byKey(Key('unit_option_$unitName')),
        )
        .evaluate()
        .isNotEmpty;
  }

  Future<void> tabToRow(WidgetTester tester, String unitName) async {
    for (var tabs = 0; tabs < 10 && !isFocusInRow(unitName); tabs++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(isFocusInRow(unitName), isTrue, reason: 'Tab never reached it');
  }

  testWidgets('Tab reaches a unit row and Enter picks it', (tester) async {
    await openSheet(tester);

    await tabToRow(tester, 'feet');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(picked, Unit.feet);
    expect(find.text('Select unit'), findsNothing);
  });

  testWidgets('puts the first heading 4 dp under the header and later '
      'headings 12 dp under the row above, as in the storyboard', (
    tester,
  ) async {
    await openSheet(tester);

    final header = tester.getRect(find.byType(SheetHeader));
    final lastLengthRow = tester.getRect(
      find.byKey(const Key('unit_option_linearFeet')),
    );
    expect(tester.getRect(find.text('BY LENGTH')).top - header.bottom, 4);
    expect(tester.getRect(find.text('BY AREA')).top - lastLengthRow.bottom, 12);
  });

  List<BoxShadow>? headerShadow(WidgetTester tester) {
    final header = tester.widget<DecoratedBox>(
      find.byKey(SelectUnitSheet.headerKey),
    );
    return (header.decoration as BoxDecoration).boxShadow;
  }

  testWidgets('draws no shadow under the header while the list is at the top', (
    tester,
  ) async {
    await openSheet(tester);

    expect(headerShadow(tester), isNull);
  });

  testWidgets('draws the header shadow when it opens scrolled to a unit, '
      'and drops it when the list is back at the top', (tester) async {
    await openSheet(tester, selected: Unit.tubes);

    expect(headerShadow(tester), CoreShadows.small);

    await tester.fling(
      find.byKey(const Key('unit_option_tubes')),
      const Offset(0, 3000),
      3000,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unit_option_feet')), findsOneWidget);
    expect(headerShadow(tester), isNull);
  });

  testWidgets('draws the header shadow once the list is dragged up', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.drag(
      find.byKey(const Key('unit_option_feet')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(headerShadow(tester), CoreShadows.small);
  });

  testWidgets('at 2.0x text, opens with whole headings and the selected unit '
      'near the end in view', (tester) async {
    await openSheet(tester, selected: Unit.tubes, textScale: 2);

    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byKey(const Key('unit_option_tubes')));
    expect(row.top, greaterThanOrEqualTo(0));
    expect(row.bottom, lessThanOrEqualTo(917));
    final heading = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text('BY PACKAGING'),
        matching: find.byType(RichText),
      ),
    );
    expect(
      heading.size.height,
      greaterThanOrEqualTo(
        heading.getMaxIntrinsicHeight(heading.size.width) - 0.5,
      ),
    );
  });
}
