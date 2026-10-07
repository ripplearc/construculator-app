import 'package:construculator/features/estimation/presentation/widgets/sheet_field_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
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
            child: const SizedBox(
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

  testWidgets('reports a tap on the label, the empty space and the value '
      'area', (tester) async {
    await pumpRow(tester);
    final row = tester.getRect(find.byKey(const Key('row')));

    await tester.tap(find.text('Quantity'));
    await tester.tapAt(Offset(row.right - 8, row.top + 30));
    await tester.tapAt(Offset(row.left + 8, row.top + 4));

    expect(taps, 3);
  });

  testWidgets('does nothing on a tap when no handler is given', (tester) async {
    await pumpRow(tester, tappable: false);

    await tester.tap(find.text('Quantity'));

    expect(taps, 0);
  });
}
