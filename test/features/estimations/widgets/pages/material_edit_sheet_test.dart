import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/guarded_quick_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
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

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_your_rates_database.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(FakeYourRatesDatabase());
  });

  tearDownAll(Modular.dispose);

  setUp(() {
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
  });

  tearDown(() => fakeSupabase.reset());

  final rebar = MaterialCostItem(
    id: 'item-1',
    estimateId: 'estimate-1',
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

  late MaterialCostFormBloc sheetBloc;

  Future<void> openEditSheet(WidgetTester tester) async {
    fakeSupabase.addTableData(DatabaseConstants.costItemsTable, [
      CostItemDto.fromEntity(rebar).toJson(),
    ]);
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    sheetBloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(sheetBloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open_sheet'),
              onPressed: () => GuardedQuickSheet.show<void>(
                context: context,
                backgroundColor: CoreTheme.light().coreColors.pageBackground,
                child: BlocProvider<MaterialCostFormBloc>.value(
                  value: sheetBloc,
                  child: CostItemFormScreen(
                    type: CostItemType.material,
                    estimationId: 'estimate-1',
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
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  Finder dialogTitle() => find.byKey(ConfirmationDialog.titleKey);

  Finder inField(String key, String text) => find.descendant(
    of: find.byKey(Key(key)),
    matching: find.textContaining(text),
  );

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pumpAndSettle();
  }

  Future<void> tapBack(WidgetTester tester) async {
    await tester.tap(find.byKey(SheetHeader.backButtonKey));
    await tester.pumpAndSettle();
  }

  Future<MaterialCostItem> storedLine() async {
    final items = await Modular.get<CostItemRepository>()
        .getCostItemsForEstimate('estimate-1');
    return items.getRightOrNull()!.single as MaterialCostItem;
  }

  group('the material sheet opened on a line already on the estimate', () {
    testWidgets('is headed by the item name', (tester) async {
      await openEditSheet(tester);

      expect(
        find.descendant(
          of: find.byType(SheetHeader),
          matching: find.text('Rebar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps the stored name in the header while it is retyped', (
      tester,
    ) async {
      await openEditSheet(tester);

      await enter(tester, 'material_name_field', 'Steel bar');

      expect(
        find.descendant(
          of: find.byType(SheetHeader),
          matching: find.text('Rebar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the stored values in the fields', (tester) async {
      await openEditSheet(tester);

      expect(inField('material_name_field', 'Rebar'), findsOneWidget);
      expect(inField('material_quantity_field', '5'), findsOneWidget);
      expect(inField('material_rate_field', '100'), findsOneWidget);
      expect(find.byKey(const Key('material_unit_pill')), findsOneWidget);
    });

    testWidgets('offers Save this line and says no change yet', (tester) async {
      await openEditSheet(tester);

      expect(
        tester
            .widget<CoreButton>(find.byKey(AddToEstimateFooter.buttonKey))
            .label,
        l10n.saveThisLineButton,
      );
      expect(find.text(l10n.noChangeYetNote), findsOneWidget);
    });

    testWidgets('closes at once on back when nothing was touched', (
      tester,
    ) async {
      await openEditSheet(tester);

      await tapBack(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.byType(SheetHeader), findsNothing);
    });

    testWidgets('keeps the stored rate confirmed after opening', (
      tester,
    ) async {
      await openEditSheet(tester);

      expect(sheetBloc.state.data.rateStatus, RateStatus.ownRateConfirmed);
    });

    testWidgets('asks "Discard changes?" once the quantity is changed', (
      tester,
    ) async {
      await openEditSheet(tester);
      await enter(tester, 'material_quantity_field', '7');

      await tapBack(tester);

      expect(find.text(l10n.discardChangesDialogTitle), findsOneWidget);
      expect(
        find.text(l10n.discardChangesDialogBody('Rebar', '\$500.00')),
        findsOneWidget,
      );
      expect(find.text(l10n.discardLineDialogTitle), findsNothing);
    });

    testWidgets('Discard closes the sheet and leaves the stored line alone', (
      tester,
    ) async {
      await openEditSheet(tester);
      await enter(tester, 'material_quantity_field', '7');
      await tapBack(tester);

      await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
      await tester.pumpAndSettle();

      expect((await storedLine()).quantity.value, 5.0);
      expect(fakeSupabase.getMethodCallsFor('update'), isEmpty);
    });

    testWidgets('shows the rise in the estimate once the quantity is changed', (
      tester,
    ) async {
      await openEditSheet(tester);

      await enter(tester, 'material_quantity_field', '7');

      expect(find.text('+\$200.00'), findsOneWidget);
    });

    testWidgets('Save this line stores the change and closes the sheet', (
      tester,
    ) async {
      await openEditSheet(tester);
      await enter(tester, 'material_quantity_field', '7');

      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pumpAndSettle();

      final line = await storedLine();
      expect(line.quantity.value, 7.0);
      expect(line.itemTotalCost, 700.0);
      expect(line.rateStatus, RateStatus.ownRateConfirmed);
      expect(fakeSupabase.getMethodCallsFor('insert'), isEmpty);
      expect(find.byType(SheetHeader), findsNothing);
    });

    group('deleting the line', () {
      Future<void> tapDelete(WidgetTester tester) async {
        await tester.tap(find.byKey(AddToEstimateFooter.deleteButtonKey));
        await tester.pumpAndSettle();
      }

      testWidgets('asks first, naming the line and the estimate', (
        tester,
      ) async {
        await openEditSheet(tester);

        await tapDelete(tester);

        expect(find.text(l10n.deleteLineDialogTitle), findsOneWidget);
        expect(
          find.text(l10n.deleteLineDialogBody('Rebar', 'Bedroom 2')),
          findsOneWidget,
        );
        expect(fakeSupabase.getMethodCallsFor('delete'), isEmpty);
      });

      testWidgets('No, Keep leaves the line stored and the sheet open', (
        tester,
      ) async {
        await openEditSheet(tester);
        await tapDelete(tester);

        await tester.tap(find.byKey(ConfirmationDialog.primaryButtonKey));
        await tester.pumpAndSettle();

        expect((await storedLine()).id, 'item-1');
        expect(find.byType(SheetHeader), findsOneWidget);
        expect(dialogTitle(), findsNothing);
      });

      testWidgets('Yes, Delete removes the stored line and closes the sheet', (
        tester,
      ) async {
        await openEditSheet(tester);
        await tapDelete(tester);

        await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
        await tester.pumpAndSettle();

        final items = await Modular.get<CostItemRepository>()
            .getCostItemsForEstimate('estimate-1');
        expect(items.getRightOrNull(), isEmpty);
        expect(find.byType(SheetHeader), findsNothing);
      });

      testWidgets('a failed delete says so and keeps the sheet open', (
        tester,
      ) async {
        await openEditSheet(tester);
        fakeSupabase.shouldThrowOnDelete = true;
        await tapDelete(tester);

        await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
        await tester.pumpAndSettle();

        expect(find.text(l10n.deleteLineFailedError), findsOneWidget);
        expect(find.byType(SheetHeader), findsOneWidget);
      });

      testWidgets('a failed save says the change was not saved', (
        tester,
      ) async {
        await openEditSheet(tester);
        await enter(tester, 'material_quantity_field', '7');
        fakeSupabase.shouldThrowOnUpdate = true;

        await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
        await tester.pumpAndSettle();

        expect(find.text(l10n.saveLineFailedError), findsOneWidget);
        expect(find.text(l10n.addToEstimateFailedError), findsNothing);
      });
    });
  });

  group('the material sheet for a new line', () {
    testWidgets('has no Delete this line button', (tester) async {
      sheetBloc = Modular.get<MaterialCostFormBloc>();
      addTearDown(sheetBloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<MaterialCostFormBloc>.value(
              value: sheetBloc,
              child: CostItemFormScreen(
                type: CostItemType.material,
                estimationId: 'estimate-1',
                router: FakeAppRouter(),
                yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
                clock: FakeClockImpl(),
                presentAsSheet: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AddToEstimateFooter.deleteButtonKey), findsNothing);
      expect(
        tester
            .widget<CoreButton>(find.byKey(AddToEstimateFooter.buttonKey))
            .label,
        isNot(l10n.saveThisLineButton),
      );
    });
  });
}
