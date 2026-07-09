import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
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
        body: MaterialCostFormFields(
          fromCostFile: fromCostFile,
          onTotalChanged: onTotalChanged,
        ),
      ),
    );
  }

  group('MaterialCostFormFields — manually mode', () {
    testWidgets('shows material type text field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('material_type_field')), findsOneWidget);
    });

    testWidgets('shows per unit cost field with dollar suffix', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('per_unit_cost_field')), findsOneWidget);
    });

    testWidgets('shows UOM dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('uom_field')), findsOneWidget);
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

    testWidgets('brand and product link hidden by default', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('brand_field')), findsNothing);
      expect(find.byKey(const Key('product_link_field')), findsNothing);
    });

    testWidgets('tapping other details button reveals brand and product link', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.otherMaterialDetailsButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('brand_field')), findsOneWidget);
      expect(find.byKey(const Key('product_link_field')), findsOneWidget);
    });

    testWidgets('tapping other details button again hides brand and product link', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.otherMaterialDetailsButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.otherMaterialDetailsButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('brand_field')), findsNothing);
      expect(find.byKey(const Key('product_link_field')), findsNothing);
    });
  });

  group('MaterialCostFormFields — from cost file mode', () {
    testWidgets('shows cost file dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cost_file_field')), findsOneWidget);
    });

    testWidgets('shows material type dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('material_type_field')), findsOneWidget);
    });

    testWidgets('shows quantity dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quantity_field')), findsOneWidget);
    });

    testWidgets('hides per unit cost field', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('per_unit_cost_field')), findsNothing);
    });

    testWidgets('hides UOM field', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('uom_field')), findsNothing);
    });

    testWidgets('reveals brand and product link on button tap', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.otherMaterialDetailsButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('brand_field')), findsOneWidget);
      expect(find.byKey(const Key('product_link_field')), findsOneWidget);
    });
  });

  group('MaterialCostFormFields — real-time total', () {
    testWidgets('calls onTotalChanged with price × quantity', (tester) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('per_unit_cost_field')),
        '10',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('quantity_field')), '3');
      await tester.pump();

      expect(capturedTotal, 30.0);
    });

    testWidgets('total updates when price changes', (tester) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('quantity_field')), '4');
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('per_unit_cost_field')),
        '25',
      );
      await tester.pump();

      expect(capturedTotal, 100.0);
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

  group('MaterialCostFormFields — accessibility', () {
    testWidgets('other details button has semantic label', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.byKey(const Key('other_material_details_button')),
      );
      expect(semantics.label, contains(l10n.otherMaterialDetailsButton));
    });
  });
}
