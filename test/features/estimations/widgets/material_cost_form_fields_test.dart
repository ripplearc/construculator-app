import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../helpers/unit_display_name_helper.dart';

void main() {
  late AppLocalizations l10n;
  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  Widget makeWidget({
    bool fromCostFile = false,
    ValueChanged<double>? onTotalChanged,
    ValueChanged<bool>? onSaveEnabledChanged,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<MaterialCostFormBloc>(
          create: (_) => Modular.get<MaterialCostFormBloc>(),
          child: MaterialCostFormFields(
            fromCostFile: fromCostFile,
            onTotalChanged: onTotalChanged,
            onSaveEnabledChanged: onSaveEnabledChanged,
          ),
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

    testWidgets('shows UOM dropdown in manual mode', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('uom_field')), findsOneWidget);
    });

    testWidgets('tapping UOM field opens unit selection bottom sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('uom_field')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectUnitTitle), findsOneWidget);
    });

    testWidgets('UOM bottom sheet lists all unit options', (tester) async {
      // Tall viewport so FractionallySizedBox(0.4) gives 1200px — enough for all 13 ListView items
      tester.view.physicalSize = const Size(390, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('uom_field')));
      await tester.pumpAndSettle();

      for (final unit in Unit.values) {
        expect(find.text(unitDisplayName(unit, l10n)), findsOneWidget);
      }
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

  group('MaterialCostFormFields — item type error', () {
    testWidgets('shows error text when material type is cleared after typing', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        'Lap Sealant',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        '',
      );
      await tester.pump();

      expect(find.text(l10n.materialTypeRequiredError), findsOneWidget);
    });

    testWidgets('hides error text when material type is non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        'Lap Sealant',
      );
      await tester.pump();

      expect(find.text(l10n.materialTypeRequiredError), findsNothing);
    });
  });

  group('MaterialCostFormFields — real-time total', () {
    testWidgets('calls onTotalChanged with perUnitCost × quantity', (
      tester,
    ) async {
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
      await tester.enterText(find.byKey(const Key('quantity_field')), '5');
      await tester.pump();

      expect(capturedTotal, 50.0);
    });

    testWidgets('total updates when per unit cost changes', (tester) async {
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

    testWidgets('calls onTotalChanged with 0 when a field is empty', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('per_unit_cost_field')),
        '20',
      );
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

    testWidgets('resets total to 0 when fromCostFile flips on a mounted widget', (
      tester,
    ) async {
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
      await tester.enterText(find.byKey(const Key('quantity_field')), '5');
      await tester.pump();

      await tester.pumpWidget(
        makeWidget(
          fromCostFile: true,
          onTotalChanged: (total) => capturedTotal = total,
        ),
      );
      await tester.pump();

      expect(capturedTotal, 0.0);
    });
  });

  group('MaterialCostFormFields — save enabled', () {
    testWidgets('calls onSaveEnabledChanged(false) initially', (tester) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(onSaveEnabledChanged: (v) => captured = v),
      );
      await tester.pumpAndSettle();

      expect(captured, isNull);
    });

    testWidgets('calls onSaveEnabledChanged(true) when material type has text', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(onSaveEnabledChanged: (v) => captured = v),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        'Lap Sealant',
      );
      await tester.pump();

      expect(captured, isTrue);
    });

    testWidgets(
        'calls onSaveEnabledChanged(false) when material type is cleared', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(onSaveEnabledChanged: (v) => captured = v),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        'Lap Sealant',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('material_type_field')), '');
      await tester.pump();

      expect(captured, isFalse);
    });

    testWidgets(
        'does not call onSaveEnabledChanged in from cost file mode', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(
          fromCostFile: true,
          onSaveEnabledChanged: (v) => captured = v,
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, isNull);
    });

    testWidgets(
        'calls onSaveEnabledChanged(false) when switching to from cost file mode after typing', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(onSaveEnabledChanged: (v) => captured = v),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        'Lap Sealant',
      );
      await tester.pump();
      expect(captured, isTrue);

      await tester.pumpWidget(
        makeWidget(fromCostFile: true, onSaveEnabledChanged: (v) => captured = v),
      );
      await tester.pump();

      expect(captured, isFalse);
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
