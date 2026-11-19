import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  var addCount = 0;

  setUp(() => addCount = 0);

  Future<void> pumpFooter(
    WidgetTester tester, {
    double? deliveryFee,
    AddToEstimateBlock? block,
    bool isBusy = false,
    String? errorMessage,
    Widget? keypad,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddToEstimateFooter(
            lineTotal: 520,
            deliveryFee: deliveryFee,
            estimateName: 'Bedroom 2',
            estimateTotal: 2993.62,
            block: block,
            isBusy: isBusy,
            errorMessage: errorMessage,
            onAdd: () => addCount++,
            keypad: keypad,
          ),
        ),
      ),
    );
  }

  const keypadKey = Key('keypad');
  const keypad = SizedBox(key: keypadKey, height: 100);

  testWidgets('draws the keypad in place of the button, edge to edge', (
    tester,
  ) async {
    await pumpFooter(tester, keypad: keypad);

    final card = tester.getRect(find.byKey(AddToEstimateFooter.panelKey));
    final pad = tester.getRect(find.byKey(keypadKey));
    expect(find.byKey(AddToEstimateFooter.buttonKey), findsNothing);
    expect(find.text('Add to estimate'), findsNothing);
    expect(pad.top, card.bottom + CoreSpacing.space4);
    expect(pad.left, 0);
    expect(pad.right, tester.getSize(find.byType(Scaffold)).width);
    expect(card.left, CoreSpacing.space5);
  });

  testWidgets('keeps the error line between the card and the keypad', (
    tester,
  ) async {
    await pumpFooter(tester, keypad: keypad, errorMessage: 'Could not add.');

    final card = tester.getRect(find.byKey(AddToEstimateFooter.panelKey));
    final error = tester.getRect(find.byKey(AddToEstimateFooter.errorKey));
    final pad = tester.getRect(find.byKey(keypadKey));
    expect(error.top, greaterThanOrEqualTo(card.bottom));
    expect(error.bottom, lessThanOrEqualTo(pad.top));
    expect(error.left, CoreSpacing.space5);
  });

  testWidgets('shows the card above the button', (tester) async {
    await pumpFooter(tester);

    final card = tester.getRect(find.byKey(AddToEstimateFooter.panelKey));
    final button = tester.getRect(find.byKey(AddToEstimateFooter.buttonKey));
    expect(find.text(r'$520.00'), findsOneWidget);
    expect(card.bottom, lessThan(button.top));
  });

  testWidgets('shows the delivery row when a fee is set', (tester) async {
    await pumpFooter(tester, deliveryFee: 85);

    expect(find.text('incl. delivery'), findsOneWidget);
    expect(find.text(r'+$85.00'), findsOneWidget);
  });

  testWidgets('calls onAdd when the button is tapped', (tester) async {
    await pumpFooter(tester);

    await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));

    expect(addCount, 1);
    expect(find.text('Add to estimate'), findsOneWidget);
  });

  testWidgets('keeps the label but ignores taps while submitting', (
    tester,
  ) async {
    await pumpFooter(tester, isBusy: true);

    await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));

    expect(addCount, 0);
    expect(find.text('Add to estimate'), findsOneWidget);
  });

  testWidgets('shows the block label and ignores taps when blocked', (
    tester,
  ) async {
    await pumpFooter(
      tester,
      block: const AddToEstimateBlock(
        note: 'Needs a rate before it can total',
        buttonLabel: 'Enter a rate to continue',
      ),
    );

    await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));

    expect(find.text('Enter a rate to continue'), findsOneWidget);
    expect(find.text('Needs a rate before it can total'), findsOneWidget);
    expect(find.text('Add to estimate'), findsNothing);
    expect(addCount, 0);
  });

  testWidgets('shows no error line unless a message is given', (tester) async {
    await pumpFooter(tester);

    expect(find.byKey(AddToEstimateFooter.errorKey), findsNothing);
  });

  testWidgets('shows the error message between the card and the button', (
    tester,
  ) async {
    await pumpFooter(tester, errorMessage: 'Could not add.');

    final card = tester.getRect(find.byKey(AddToEstimateFooter.panelKey));
    final error = tester.getRect(find.byKey(AddToEstimateFooter.errorKey));
    final button = tester.getRect(find.byKey(AddToEstimateFooter.buttonKey));
    expect(find.text('Could not add.'), findsOneWidget);
    expect(error.top, greaterThanOrEqualTo(card.bottom));
    expect(error.bottom, lessThanOrEqualTo(button.top));
  });

  testWidgets('keeps the button usable when it shows an error', (tester) async {
    await pumpFooter(tester, errorMessage: 'Could not add.');

    await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));

    expect(addCount, 1);
  });
}
