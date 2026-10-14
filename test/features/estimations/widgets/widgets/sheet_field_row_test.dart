import 'package:construculator/features/estimation/presentation/widgets/sheet_field_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  var taps = 0;

  setUp(() => taps = 0);

  Future<void> pumpRow(
    WidgetTester tester, {
    double? valueGap,
    double? bottomPadding,
    bool tappable = true,
    Widget? value,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SheetFieldRow(
            key: const Key('row'),
            label: 'Quantity',
            valueGap: valueGap ?? CoreSpacing.space1,
            bottomPadding: bottomPadding ?? CoreSpacing.space3,
            onTap: tappable ? () => taps++ : null,
            child:
                value ??
                const SizedBox(
                  key: Key('value'),
                  height: 24,
                  width: 40,
                  child: Text('3'),
                ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the label above the value and a divider under both', (
    tester,
  ) async {
    await pumpRow(tester);

    final label = tester.getRect(find.text('Quantity'));
    final value = tester.getRect(find.byKey(const Key('value')));
    expect(label.bottom, lessThan(value.top));
    expect(find.byType(CoreDivider), findsOneWidget);
    expect(
      tester.getRect(find.byType(CoreDivider)).top,
      greaterThanOrEqualTo(value.bottom),
    );
  });

  testWidgets('is 72 dp tall with its 4 dp gap and 12 dp padding, plus the '
      'divider', (tester) async {
    await pumpRow(tester);

    expect(
      tester.getSize(find.byKey(const Key('row'))).height,
      12 + 20 + 4 + 24 + 12 + 1,
    );
  });

  testWidgets('takes its value gap and bottom padding from the caller', (
    tester,
  ) async {
    await pumpRow(tester, valueGap: 3, bottomPadding: 7);

    final label = tester.getRect(find.text('Quantity'));
    final value = tester.getRect(find.byKey(const Key('value')));
    expect(value.top - label.bottom, 3);
    expect(
      tester.getSize(find.byKey(const Key('row'))).height,
      12 + 20 + 3 + 24 + 7 + 1,
    );
  });

  testWidgets('reports a tap on the label, the empty space and the value', (
    tester,
  ) async {
    await pumpRow(tester);
    final row = tester.getRect(find.byKey(const Key('row')));

    await tester.tap(find.text('Quantity'));
    await tester.tapAt(Offset(row.right - 8, row.top + 30));
    await tester.tap(find.byKey(const Key('value')));

    expect(taps, 3);
  });

  testWidgets('gives a button inside the row the tap instead of the row', (
    tester,
  ) async {
    var buttonTaps = 0;
    await pumpRow(
      tester,
      value: TextButton(
        key: const Key('inner_button'),
        onPressed: () => buttonTaps++,
        child: const Text('Liters'),
      ),
    );

    await tester.tap(find.byKey(const Key('inner_button')));

    expect(buttonTaps, 1);
    expect(taps, 0);
  });

  testWidgets('insets the divider 20 dp and the label 22 dp from the edges', (
    tester,
  ) async {
    await pumpRow(tester);

    final row = tester.getRect(find.byKey(const Key('row')));
    final divider = tester.getRect(
      find.descendant(
        of: find.byType(CoreDivider),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(divider.left - row.left, 20);
    expect(row.right - divider.right, 20);
    expect(tester.getRect(find.text('Quantity')).left - row.left, 22);
  });

  testWidgets('is announced once, by the value, with no extra stop for the '
      'row', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpRow(
      tester,
      value: Semantics(
        label: 'Quantity',
        child: SizedBox(key: Key('value'), height: 24, width: 40),
      ),
    );

    expect(find.bySemanticsLabel('Quantity'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('row')))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    handle.dispose();
  });

  testWidgets('does nothing on a tap when no handler is given', (tester) async {
    await pumpRow(tester, tappable: false);

    await tester.tap(find.text('Quantity'));

    expect(taps, 0);
  });
}
