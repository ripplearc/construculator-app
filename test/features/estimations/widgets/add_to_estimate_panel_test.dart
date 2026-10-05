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
    AddToEstimateBlock? block,
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
            deliveryFee: deliveryFee,
            estimateName: estimateName,
            estimateTotal: 2993.62,
            block: block,
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
  });
}
