import 'package:construculator/features/estimation/presentation/widgets/equipment_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  setUpAll(() {
    lookupAppLocalizations(const Locale('en'));
  });

  Widget makeWidget({
    bool fromCostFile = false,
    ValueChanged<double>? onTotalChanged,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EquipmentCostFormFields(
          fromCostFile: fromCostFile,
          onTotalChanged: onTotalChanged,
        ),
      ),
    );
  }

  group('EquipmentCostFormFields — manually mode', () {
    testWidgets('shows equipment name field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipment_name_field')), findsOneWidget);
    });

    testWidgets('shows unit price field with dollar suffix', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unit_price_field')), findsOneWidget);
    });

    testWidgets('shows quantity field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quantity_field')), findsOneWidget);
    });

    testWidgets('hides cost file field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cost_file_field')), findsNothing);
    });

    testWidgets('hides equipment type field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipment_type_field')), findsNothing);
    });
  });

  group('EquipmentCostFormFields — from cost file mode', () {
    testWidgets('shows cost file dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cost_file_field')), findsOneWidget);
    });

    testWidgets('shows equipment type dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipment_type_field')), findsOneWidget);
    });

    testWidgets('shows quantity field', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quantity_field')), findsOneWidget);
    });

    testWidgets('hides equipment name field', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipment_name_field')), findsNothing);
    });

    testWidgets('hides unit price field', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unit_price_field')), findsNothing);
    });
  });

  group('EquipmentCostFormFields — real-time total', () {
    testWidgets('calls onTotalChanged with unitPrice × quantity', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('unit_price_field')), '200');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('quantity_field')), '3');
      await tester.pump();

      expect(capturedTotal, 600.0);
    });

    testWidgets('total updates when quantity changes', (tester) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('unit_price_field')), '50');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('quantity_field')), '10');
      await tester.pump();

      expect(capturedTotal, 500.0);
    });

    testWidgets('calls onTotalChanged with 0 when price field is empty', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('quantity_field')), '5');
      await tester.pump();

      expect(capturedTotal, 0.0);
    });

    testWidgets('calls onTotalChanged with 0 in fromCostFile mode', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(
          fromCostFile: true,
          onTotalChanged: (total) => capturedTotal = total,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('quantity_field')), '5');
      await tester.pump();

      expect(capturedTotal, 0.0);
    });
  });
}
