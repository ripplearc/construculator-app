import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_your_rates_database.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 917);
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(FakeYourRatesDatabase());
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() async {
    fakeSupabase.reset();
    await loadAppFontsAll();
  });

  final rebar = MaterialCostItem(
    id: 'item-1',
    estimateId: 'test-estimation-id',
    itemName: 'Rebar',
    calculation: const {'unit_price': 100.0, 'quantity': 5.0},
    itemTotalCost: 500.0,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    currency: 'USD',
    unitPrice: const Money(amount: 100.0),
    quantity: const Quantity(value: 5.0, unit: Unit.pieces),
    rateStatus: RateStatus.ownRateConfirmed,
    quantityProvenance: QuantityProvenance.manual,
  );

  Future<void> openEditSheet(WidgetTester tester, ThemeData theme) async {
    fakeSupabase.addTableData(DatabaseConstants.costItemsTable, [
      CostItemDto.fromEntity(rebar).toJson(),
    ]);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_sheet'),
                onPressed: () => CoreQuickSheet.show(
                  context: context,
                  backgroundColor: sheetSurface(context),
                  child: BlocProvider<MaterialCostFormBloc>(
                    create: (_) => Modular.get<MaterialCostFormBloc>(),
                    child: CostItemFormScreen(
                      type: CostItemType.material,
                      estimationId: 'test-estimation-id',
                      router: FakeAppRouter(),
                      yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
                      clock: FakeClockImpl(),
                      presentAsSheet: true,
                      editedMaterialItem: rebar,
                      estimate: CostEstimate.defaultEstimate(
                        estimateName: 'Bedroom 2',
                        totalCost: 2993.62,
                      ),
                    ),
                  ),
                ),
                child: const Text('Edit material cost'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pumpAndSettle();
  }

  Future<void> expectSheetGolden(
    WidgetTester tester,
    String name,
    String suffix,
  ) async {
    // A focused field draws a blinking caret that changes between runs.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/material_edit_sheet/$name$suffix.png'),
    );
  }

  screenshotThemeGroups('Material sheet edit Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('opened, no change yet', (tester) async {
      await openEditSheet(tester, theme);
      await expectSheetGolden(tester, 'no_change_yet', suffix);
    });

    testWidgets('the quantity grows', (tester) async {
      await openEditSheet(tester, theme);
      await enter(tester, 'material_quantity_field', '7');
      await expectSheetGolden(tester, 'change_up', suffix);
    });

    testWidgets('the rate falls', (tester) async {
      await openEditSheet(tester, theme);
      await enter(tester, 'material_rate_field', '85.50');
      await expectSheetGolden(tester, 'change_down', suffix);
    });

    testWidgets('the save failed', (tester) async {
      await openEditSheet(tester, theme);
      await enter(tester, 'material_quantity_field', '7');
      fakeSupabase.shouldThrowOnUpdate = true;
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pumpAndSettle();
      await expectSheetGolden(tester, 'save_failed', suffix);
    });

    testWidgets('asking before the line is deleted', (tester) async {
      await openEditSheet(tester, theme);
      await tester.tap(find.byKey(AddToEstimateFooter.deleteButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(ConfirmationDialog.titleKey), findsOneWidget);
      await expectSheetGolden(tester, 'delete_dialog', suffix);
    });

    testWidgets('the delete failed', (tester) async {
      await openEditSheet(tester, theme);
      fakeSupabase.shouldThrowOnDelete = true;
      await tester.tap(find.byKey(AddToEstimateFooter.deleteButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
      await tester.pumpAndSettle();
      await expectSheetGolden(tester, 'delete_failed', suffix);
    });
  });
}
