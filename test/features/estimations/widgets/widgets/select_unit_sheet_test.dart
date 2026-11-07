import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/material_unit_list.dart';
import 'package:construculator/features/estimation/presentation/widgets/select_unit_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Unit? picked;

  setUp(() => picked = null);

  Future<void> openSheet(WidgetTester tester, {Unit? selected}) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('shows each unit with its symbol and name', (tester) async {
    await openSheet(tester);

    expect(find.text('gal'), findsOneWidget);
    expect(find.text('Gallon — paint, adhesive'), findsOneWidget);
    expect(find.text('sht'), findsOneWidget);
    expect(find.text('Sheet — 4×8 panel goods'), findsOneWidget);
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

  testWidgets('opens scrolled to a selected unit near the end', (
    tester,
  ) async {
    await openSheet(tester, selected: Unit.tubes);

    final row = tester.getRect(find.byKey(const Key('unit_option_tubes')));
    expect(row.top, greaterThan(0));
    expect(row.bottom, lessThanOrEqualTo(917));
    expect(
      tester.getSemantics(find.byKey(const Key('unit_option_tubes'))),
      isSemantics(isChecked: true, label: 'tb, Tube'),
    );
  });

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
      'headings 16 dp under the row above, as in the storyboard', (
    tester,
  ) async {
    await openSheet(tester);

    final header = tester.getRect(find.byType(SheetHeader));
    final lastLengthRow = tester.getRect(
      find.byKey(const Key('unit_option_linearFeet')),
    );
    expect(tester.getRect(find.text('BY LENGTH')).top - header.bottom, 4);
    expect(tester.getRect(find.text('BY AREA')).top - lastLengthRow.bottom, 16);
  });
}
