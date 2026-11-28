import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpPanel(
    WidgetTester tester, {
    double lineTotal = 520,
    double? deliveryFee,
    String estimateName = 'Bedroom 2',
    double? estimateTotal = 2993.62,
    AddToEstimateBlock? block,
    bool isEditingExistingLine = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddToEstimatePanel(
            lineTotal: lineTotal,
            charge: switch (deliveryFee) {
              final fee? => AddToEstimateCharge(
                label: 'incl. delivery',
                amount: fee,
              ),
              null => null,
            },
            estimateName: estimateName,
            estimateTotal: estimateTotal,
            block: block,
            isEditingExistingLine: isEditingExistingLine,
          ),
        ),
      ),
    );
  }

  group('ready', () {
    testWidgets(
      'shows the line total and the estimate total before and after',
      (tester) async {
        await pumpPanel(tester);

        expect(find.text('Adds to this estimate'), findsOneWidget);
        expect(find.text(r'$520.00'), findsOneWidget);
        expect(find.text('Bedroom 2'), findsOneWidget);
        expect(find.text(r' total  $2,993.62 →'), findsOneWidget);
        expect(find.text(r'$3,513.62'), findsOneWidget);
      },
    );

    testWidgets('shows the delivery row when the fee is above zero', (
      tester,
    ) async {
      await pumpPanel(tester, lineTotal: 605, deliveryFee: 85);

      expect(find.text('incl. delivery'), findsOneWidget);
      expect(find.text(r'+$85.00'), findsOneWidget);
    });

    for (final fee in <double?>[null, 0]) {
      testWidgets('hides the delivery row when the fee is $fee', (
        tester,
      ) async {
        await pumpPanel(tester, deliveryFee: fee);

        expect(find.text('incl. delivery'), findsNothing);
      });
    }

    testWidgets('truncates a long estimate name instead of overflowing', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        estimateName: 'Master bedroom, flooring, drywall and trim' * 3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(r' total  $2,993.62 →'), findsOneWidget);
      expect(find.text(r'$3,513.62'), findsOneWidget);
    });

    testWidgets('scales a very large total down instead of overflowing', (
      tester,
    ) async {
      await pumpPanel(tester, lineTotal: 99999999999999);

      expect(tester.takeException(), isNull);
      expect(
        find.ancestor(
          of: find.text(r'$99,999,999,999,999.00'),
          matching: find.byType(FittedBox),
        ),
        findsOneWidget,
      );
    });
  });

  group('estimate total not known', () {
    testWidgets('shows a dash before and after instead of a total', (
      tester,
    ) async {
      await pumpPanel(tester, estimateTotal: null);

      expect(find.text('Bedroom 2'), findsOneWidget);
      expect(find.text(r' total  — →'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('never shows a made-up total', (tester) async {
      await pumpPanel(tester, estimateTotal: null);

      expect(find.textContaining(r'$0.00'), findsNothing);
      expect(find.text(r'$520.00'), findsOneWidget);
      expect(find.textContaining(r'$2,993.62'), findsNothing);
    });

    testWidgets('keeps the line amount and the delivery row', (tester) async {
      await pumpPanel(
        tester,
        lineTotal: 605,
        deliveryFee: 85,
        estimateTotal: null,
      );

      expect(find.text(r'$605.00'), findsOneWidget);
      expect(find.text('incl. delivery'), findsOneWidget);
      expect(find.text(r'+$85.00'), findsOneWidget);
    });

    testWidgets('a known total of zero is shown as an amount, not a dash', (
      tester,
    ) async {
      await pumpPanel(tester, estimateTotal: 0);

      expect(find.text(r' total  $0.00 →'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('a blocked line still shows its note', (tester) async {
      await pumpPanel(
        tester,
        estimateTotal: null,
        block: const AddToEstimateBlock(
          note: 'Needs a rate before it can total',
          buttonLabel: 'Enter a rate to continue',
        ),
      );

      expect(find.text('Needs a rate before it can total'), findsOneWidget);
      expect(find.textContaining(' total  '), findsNothing);
    });
  });

  group('blocked', () {
    const block = AddToEstimateBlock(
      note: 'Needs a rate before it can total',
      buttonLabel: 'Enter a rate to continue',
    );

    testWidgets('shows the note instead of the totals', (tester) async {
      await pumpPanel(tester, block: block, deliveryFee: 85);

      expect(find.text('Needs a rate before it can total'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('incl. delivery'), findsNothing);
      expect(find.text(r'$520.00'), findsNothing);
      expect(find.text('Bedroom 2'), findsNothing);
      expect(find.textContaining('total  '), findsNothing);
    });

    testWidgets(
      'keeps the edit title over a stored line while a number is missing',
      (tester) async {
        await pumpPanel(tester, block: block, isEditingExistingLine: true);

        expect(find.text('Changes this estimate'), findsOneWidget);
        expect(find.text('Adds to this estimate'), findsNothing);
      },
    );

    testWidgets('titles the card as an addition for a new line', (
      tester,
    ) async {
      await pumpPanel(tester, block: block);

      expect(find.text('Adds to this estimate'), findsOneWidget);
      expect(find.text('Changes this estimate'), findsNothing);
    });
  });
}
