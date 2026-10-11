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
    bool isSubmitting = false,
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
            isSubmitting: isSubmitting,
            onAdd: () => addCount++,
          ),
        ),
      ),
    );
  }

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
    await pumpFooter(tester, isSubmitting: true);

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
}
