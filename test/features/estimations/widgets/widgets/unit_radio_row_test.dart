import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_radio_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late int selections;

  setUp(() => selections = 0);

  Future<void> pumpRows(WidgetTester tester, {Unit? selected}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              for (final unit in [Unit.feet, Unit.inches])
                UnitRadioRow(
                  unit: unit,
                  isSelected: unit == selected,
                  onSelected: () => selections++,
                ),
            ],
          ),
        ),
      ),
    );
  }

  final focusRing = Border.all(
    color: CoreTheme.light().extension<AppColorsExtension>()!.outlineFocus,
    width: 2,
  );

  Border? ringOf(WidgetTester tester, Unit unit) {
    final ring = tester.widget<DecoratedBox>(
      find.byKey(Key('unit_focus_ring_${unit.name}')),
    );
    return (ring.decoration as BoxDecoration).border as Border?;
  }

  testWidgets('reads the symbol and the name as one label, as a radio', (
    tester,
  ) async {
    await pumpRows(tester, selected: Unit.feet);

    expect(
      tester.getSemantics(find.byKey(const Key('unit_option_feet'))),
      isSemantics(
        label: 'ft, Foot',
        isButton: false,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    // The texts inside are not read again as their own nodes.
    expect(
      tester
          .getSemantics(find.byKey(const Key('unit_option_feet')))
          .childrenCount,
      0,
    );
    expect(
      tester.getSemantics(find.byKey(const Key('unit_option_inches'))),
      isSemantics(label: 'in, Inch', isChecked: false),
    );
  });

  testWidgets('a tap selects the row once', (tester) async {
    await pumpRows(tester);

    await tester.tap(find.byKey(const Key('unit_option_inches')));
    await tester.pump();

    expect(selections, 1);
  });

  testWidgets('Tab reaches the first row and rings it 2 dp in outlineFocus', (
    tester,
  ) async {
    await pumpRows(tester);
    expect(ringOf(tester, Unit.feet), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(ringOf(tester, Unit.feet), focusRing);
    expect(ringOf(tester, Unit.inches), isNull);
  });

  testWidgets('a second Tab moves the ring to the next row', (tester) async {
    await pumpRows(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(ringOf(tester, Unit.feet), isNull);
    expect(ringOf(tester, Unit.inches), focusRing);
  });

  testWidgets('a tap after Tab hides the ring', (tester) async {
    await pumpRows(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(ringOf(tester, Unit.feet), focusRing);

    await tester.tap(find.byKey(const Key('unit_option_inches')));
    await tester.pump();

    expect(ringOf(tester, Unit.feet), isNull);
    expect(ringOf(tester, Unit.inches), isNull);
  });

  testWidgets('a screen reader tap selects the row once', (tester) async {
    await pumpRows(tester);

    tester.semantics.tap(find.semantics.byLabel('in, Inch'));
    await tester.pump();

    expect(selections, 1);
  });

  for (final (name, key) in [
    ('Enter', LogicalKeyboardKey.enter),
    ('Space', LogicalKeyboardKey.space),
  ]) {
    testWidgets('$name on a focused row selects it once', (tester) async {
      await pumpRows(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(key);
      await tester.pump();

      expect(selections, 1);
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('at 2.0x text in ${direction.name}, the longest name wraps '
        'inside the row, clear of the symbol', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
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
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(textDirection: direction, child: child!),
          ),
          home: Scaffold(
            body: UnitRadioRow(
              unit: Unit.pounds,
              isSelected: true,
              onSelected: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byKey(const Key('unit_option_pounds')));
      final symbol = tester.getRect(find.text('lb'));
      final name = tester.getRect(find.text('Pound — fasteners, compound'));
      expect(row.height, greaterThanOrEqualTo(48));
      expect(symbol.overlaps(name), isFalse);
      for (final text in ['lb', 'Pound — fasteners, compound']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        );
        final fullHeight = paragraph.getMaxIntrinsicHeight(
          paragraph.size.width,
        );
        expect(paragraph.size.height, greaterThanOrEqualTo(fullHeight - 0.5));
      }
    });
  }
}
