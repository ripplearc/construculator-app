import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/number_pad_session.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_cost_items_database.dart';
import '../../helpers/cost_item_test_data_map_factory.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeCostItemsDatabase database;
  late MaterialCostFormBloc bloc;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    database = FakeCostItemsDatabase();
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
  });

  tearDownAll(Modular.dispose);

  setUp(() {
    fakeSupabase.reset();
    database.reset();
  });

  Future<void> pumpFooter(
    WidgetTester tester, {
    NumberPadSession Function()? numberPad,
    FocusNode? fieldFocus,
    bool isSplit = false,
  }) async {
    bloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(bloc.close);
    final session = numberPad?.call();
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_sheet'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: BlocProvider<MaterialCostFormBloc>.value(
                        value: bloc,
                        child: Column(
                          children: [
                            Focus(
                              focusNode: fieldFocus,
                              child: const SizedBox(),
                            ),
                            for (final part
                                in isSplit
                                    ? const [
                                        AddToEstimateFooterPart.panel,
                                        AddToEstimateFooterPart.controls,
                                      ]
                                    : const [AddToEstimateFooterPart.all])
                              MaterialAddToEstimateFooter(
                                estimateId: 'estimate-1',
                                estimateName: 'Bedroom 2',
                                estimateTotal: 2093.02,
                                numberPad: session,
                                part: part,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String? name,
    String? quantity,
    Unit? unit,
    String? rate,
    String? waste,
  }) async {
    if (name != null) bloc.add(MaterialCostItemTypeChanged(name));
    if (quantity != null) bloc.add(MaterialQuantityUpdated(quantity));
    if (unit != null) bloc.add(MaterialUnitSelected(unit));
    if (rate != null) bloc.add(MaterialRateUpdated(rate));
    if (waste != null) bloc.add(MaterialWasteUpdated(waste));
    await tester.pumpAndSettle();
  }

  void holdSaves() {
    final held = Completer<void>();
    database.writeGate = held;
    addTearDown(() {
      if (!held.isCompleted) held.complete();
    });
  }

  bool isButtonDisabled(WidgetTester tester) => tester
      .widget<CoreButton>(find.byKey(AddToEstimateFooter.buttonKey))
      .isDisabled;

  group('what the button and card say while Add is disabled', () {
    testWidgets('names the material name first when the form is empty', (
      tester,
    ) async {
      await pumpFooter(tester);

      expect(find.text('Enter a material name to continue'), findsOneWidget);
      expect(find.text('Needs a name before it can total'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(isButtonDisabled(tester), isTrue);
    });

    testWidgets('asks for a quantity once the name is set', (tester) async {
      await pumpFooter(tester);
      await fill(tester, name: 'Interior paint');

      expect(find.text('Enter a quantity to continue'), findsOneWidget);
      expect(find.text('Needs a quantity before it can total'), findsOneWidget);
    });

    testWidgets('says to fix a quantity of zero', (tester) async {
      await pumpFooter(tester);
      await fill(tester, name: 'Interior paint', quantity: '0');

      expect(find.text('Fix the quantity to continue'), findsOneWidget);
      expect(
        find.text('Needs a quantity above zero before it can total'),
        findsOneWidget,
      );
    });

    testWidgets('says to fix a quantity too large to store', (tester) async {
      await pumpFooter(tester);
      await fill(tester, name: 'Interior paint', quantity: '100000000000000');

      expect(find.text('Fix the quantity to continue'), findsOneWidget);
      expect(
        find.text('Needs a valid quantity before it can total'),
        findsOneWidget,
      );
    });

    testWidgets('asks for a unit once name and quantity are set', (
      tester,
    ) async {
      await pumpFooter(tester);
      await fill(tester, name: 'Interior paint', quantity: '3');

      expect(find.text('Enter a unit to continue'), findsOneWidget);
      expect(find.text('Needs a unit before it can total'), findsOneWidget);
    });

    testWidgets('asks for a rate last, as in the Figma screen', (tester) async {
      await pumpFooter(tester);
      await fill(
        tester,
        name: 'Interior paint',
        quantity: '3',
        unit: Unit.liters,
      );

      expect(find.text('Enter a rate to continue'), findsOneWidget);
      expect(find.text('Needs a rate before it can total'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('says to fix a rate outside the allowed range', (tester) async {
      await pumpFooter(tester);
      await fill(
        tester,
        name: 'Interior paint',
        quantity: '3',
        unit: Unit.liters,
        rate: '1000000',
      );

      expect(find.text('Fix the rate to continue'), findsOneWidget);
      expect(
        find.text('Needs a valid rate before it can total'),
        findsOneWidget,
      );
    });
  });

  group('when every field is set', () {
    Future<void> fillAll(WidgetTester tester) => fill(
      tester,
      name: 'Interior paint',
      quantity: '7',
      unit: Unit.liters,
      rate: '2.55',
    );

    testWidgets('enables Add the moment the fourth value arrives', (
      tester,
    ) async {
      await pumpFooter(tester);
      await fill(
        tester,
        name: 'Interior paint',
        quantity: '7',
        unit: Unit.liters,
      );
      expect(isButtonDisabled(tester), isTrue);

      await fill(tester, rate: '2.55');

      expect(isButtonDisabled(tester), isFalse);
      expect(find.text('Add to estimate'), findsOneWidget);
    });

    testWidgets('shows the line total with the 10% a new material starts '
        'with, and the estimate before and after', (tester) async {
      await pumpFooter(tester);
      await fillAll(tester);

      expect(find.text(r'$19.64'), findsOneWidget);
      expect(find.text('incl. 10% waste'), findsOneWidget);
      expect(find.text(r'$2,112.66'), findsOneWidget);
      expect(find.textContaining('Bedroom 2'), findsOneWidget);
    });

    testWidgets('shows the waste in the line total and on its own row', (
      tester,
    ) async {
      await pumpFooter(tester);
      await fill(
        tester,
        name: 'Interior paint',
        quantity: '3',
        unit: Unit.gallons,
        rate: '52',
        waste: '15',
      );

      expect(find.text(r'$179.40'), findsOneWidget);
      expect(find.text('incl. 15% waste'), findsOneWidget);
      expect(find.text(r'+$23.40'), findsOneWidget);
      expect(find.text(r'$2,272.42'), findsOneWidget);
    });

    testWidgets('names a part percentage with its decimal', (tester) async {
      await pumpFooter(tester);
      await fillAll(tester);
      await fill(tester, waste: '12.5');

      expect(find.text('incl. 12.5% waste'), findsOneWidget);
      expect(find.text(r'+$2.23'), findsOneWidget);
    });

    testWidgets('updates the waste row when the waste is changed again', (
      tester,
    ) async {
      await pumpFooter(tester);
      await fill(
        tester,
        name: 'Interior paint',
        quantity: '3',
        unit: Unit.gallons,
        rate: '52',
        waste: '15',
      );
      await fill(tester, waste: '10');

      expect(find.text('incl. 15% waste'), findsNothing);
      expect(find.text('incl. 10% waste'), findsOneWidget);
      expect(find.text(r'+$15.60'), findsOneWidget);
      expect(find.text(r'$171.60'), findsOneWidget);
    });

    testWidgets('keeps the waste row while the line saves', (tester) async {
      await pumpFooter(tester);
      await fillAll(tester);
      await fill(tester, waste: '15');
      holdSaves();

      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      final disabledWhileSaving = isButtonDisabled(tester);
      final wasteRows = find.text('incl. 15% waste').evaluate().length;
      final wasteAmounts = find.text(r'+$2.68').evaluate().length;

      database.writeGate!.complete();
      await tester.pumpAndSettle();

      expect(disabledWhileSaving, isTrue);
      expect(wasteRows, 1);
      expect(wasteAmounts, 1);
    });

    testWidgets('keeps the waste row after a failed save and updates it when '
        'the waste is edited', (tester) async {
      database.executeError = StateError('disk full');
      await pumpFooter(tester);
      await fillAll(tester);
      await fill(tester, waste: '15');
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(AddToEstimateFooter.errorKey), findsOneWidget);
      expect(find.text('incl. 15% waste'), findsOneWidget);

      await fill(tester, waste: '10');

      expect(find.byKey(AddToEstimateFooter.errorKey), findsOneWidget);
      expect(find.text('incl. 10% waste'), findsOneWidget);
      expect(find.text(r'+$1.79'), findsOneWidget);
    });

    for (final waste in ['', '0']) {
      testWidgets('shows no waste row for a waste of "$waste"', (tester) async {
        await pumpFooter(tester);
        await fillAll(tester);
        await fill(tester, waste: '15');
        await fill(tester, waste: waste);

        expect(find.textContaining('waste'), findsNothing);
        expect(find.text(r'$17.85'), findsOneWidget);
      });
    }

    testWidgets('shows a part quantity total without losing a half cent', (
      tester,
    ) async {
      await pumpFooter(tester);
      await fill(
        tester,
        name: 'Nails',
        quantity: '0.5',
        unit: Unit.boxes,
        rate: '2.01',
        waste: '',
      );

      expect(find.text(r'$1.01'), findsOneWidget);
    });

    testWidgets('a footer split into card and controls closes the sheet '
        'once after the add', (tester) async {
      await pumpFooter(tester, isSplit: true);
      await fillAll(tester);
      expect(find.byKey(AddToEstimateFooter.panelKey), findsOneWidget);

      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pumpAndSettle();

      expect(database.rows, hasLength(1));
      expect(find.byType(MaterialAddToEstimateFooter), findsNothing);
      expect(find.byKey(const Key('open_sheet')), findsOneWidget);
    });

    testWidgets('saves the line and closes the sheet when Add is tapped', (
      tester,
    ) async {
      await pumpFooter(tester);
      await fillAll(tester);

      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pumpAndSettle();

      expect(database.rows, hasLength(1));
      expect(find.byType(MaterialAddToEstimateFooter), findsNothing);
    });

    testWidgets('keeps the sheet open and says so above the button when '
        'saving fails', (tester) async {
      database.executeError = StateError('disk full');
      await pumpFooter(tester);
      await fillAll(tester);

      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialAddToEstimateFooter), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(AddToEstimateFooter.errorKey),
          matching: find.text('This cost was not added. Try again.'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byKey(AddToEstimateFooter.errorKey)).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(AddToEstimateFooter.buttonKey)).top,
        ),
      );
      expect(isButtonDisabled(tester), isFalse);
    });

    testWidgets('disables the button at once and keeps its label while the '
        'line saves', (tester) async {
      await pumpFooter(tester);
      await fillAll(tester);
      holdSaves();

      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();

      expect(isButtonDisabled(tester), isTrue);
      expect(find.text('Add to estimate'), findsOneWidget);

      database.writeGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows no error line before a save has failed', (tester) async {
      await pumpFooter(tester);
      await fillAll(tester);

      expect(find.byKey(AddToEstimateFooter.errorKey), findsNothing);
    });

    testWidgets('removes the error line while the next save runs and shows '
        'it again if that fails too', (tester) async {
      database.executeError = StateError('disk full');
      await pumpFooter(tester);
      await fillAll(tester);
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(AddToEstimateFooter.errorKey), findsOneWidget);

      holdSaves();
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      expect(find.byKey(AddToEstimateFooter.errorKey), findsNothing);

      database.writeGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(AddToEstimateFooter.errorKey), findsOneWidget);
    });

    testWidgets('keeps the error line while a field is edited and removes it '
        'when Add is tapped again', (tester) async {
      database.executeError = StateError('disk full');
      await pumpFooter(tester);
      await fillAll(tester);
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(AddToEstimateFooter.errorKey), findsOneWidget);

      bloc.add(const MaterialQuantityUpdated('8'));
      await tester.pump();
      expect(find.byKey(AddToEstimateFooter.errorKey), findsOneWidget);

      holdSaves();
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      expect(find.byKey(AddToEstimateFooter.errorKey), findsNothing);

      database.writeGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('adds the line on a second try and closes the sheet', (
      tester,
    ) async {
      database.executeError = StateError('disk full');
      await pumpFooter(tester);
      await fillAll(tester);
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      await tester.pump();

      database.executeError = null;
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialAddToEstimateFooter), findsNothing);
    });
  });

  group('with the number pad up on the quantity', () {
    late TextEditingController quantity;

    NumberPadSession quantityPad() {
      quantity = TextEditingController(text: '7');
      addTearDown(quantity.dispose);
      return NumberPadSession(
        controller: quantity,
        formatter: FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        onChanged: (value) => bloc.add(MaterialQuantityUpdated(value)),
        putBackLabelOf: (openedWith) => 'Back to $openedWith',
      );
    }

    Future<void> fillOthers(WidgetTester tester) => fill(
      tester,
      name: 'Interior paint',
      quantity: '7',
      unit: Unit.liters,
      rate: '2.55',
    );

    testWidgets('hides the form button and shows the pad under the card', (
      tester,
    ) async {
      await pumpFooter(tester, numberPad: quantityPad);
      await fillOthers(tester);

      expect(find.byKey(AddToEstimateFooter.buttonKey), findsNothing);
      expect(find.byKey(CoreNumberKeypad.confirmButtonKey), findsOneWidget);
      expect(find.text('Back to 7'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(AddToEstimateFooter.panelKey)).bottom,
        lessThan(tester.getRect(find.byType(CoreNumberKeypad)).top),
      );
    });

    testWidgets('every key reaches the field and the card totals on each '
        'keystroke', (tester) async {
      await pumpFooter(tester, numberPad: quantityPad);
      await fillOthers(tester);

      await tester.tap(find.byKey(const Key('calc_key_one')));
      await tester.tap(find.byKey(const Key('calc_key_decimal')));
      await tester.tap(find.byKey(const Key('calc_key_five')));
      await tester.pumpAndSettle();
      expect(quantity.text, '71.5');
      expect(find.text(r'$200.56'), findsOneWidget);

      await tester.tap(find.byKey(const Key('calc_key_delete')));
      await tester.pumpAndSettle();
      expect(quantity.text, '71.');
    });

    testWidgets('the confirm key adds the whole cost, like the form button', (
      tester,
    ) async {
      await pumpFooter(tester, numberPad: quantityPad);
      await fillOthers(tester);

      await tester.tap(find.byKey(CoreNumberKeypad.confirmButtonKey));
      await tester.pumpAndSettle();

      expect(database.rows, hasLength(1));
      expect(find.byType(MaterialAddToEstimateFooter), findsNothing);
    });

    testWidgets('the confirm key is disabled and adds nothing while a field '
        'is missing', (tester) async {
      await pumpFooter(tester, numberPad: quantityPad);
      await fill(tester, name: 'Interior paint', quantity: '7');

      await tester.tap(find.byKey(CoreNumberKeypad.confirmButtonKey));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CoreNumberKeypad>(find.byType(CoreNumberKeypad))
            .isConfirmEnabled,
        isFalse,
      );
      expect(find.text('Add to estimate'), findsOneWidget);
      expect(database.rows, isEmpty);
    });

    testWidgets('locks every key while the line saves, as the read-only '
        'fields are', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await pumpFooter(tester, numberPad: quantityPad, fieldFocus: focus);
      await fillOthers(tester);
      focus.requestFocus();
      holdSaves();
      await tester.tap(find.byKey(CoreNumberKeypad.confirmButtonKey));
      await tester.pump();

      for (final key in ['calc_key_one', 'calc_key_decimal', 'calc_key_nine']) {
        await tester.tap(find.byKey(Key(key)));
      }
      await tester.pump();
      final afterTyping = quantity.text;
      await tester.tap(find.byKey(const Key('calc_key_delete')));
      await tester.pump();
      final afterBackspace = quantity.text;
      await tester.tap(find.byKey(CoreNumberKeypad.clearButtonKey));
      await tester.pump();
      final focusedAfterPutBack = focus.hasFocus;
      final isConfirmEnabled = tester
          .widget<CoreNumberKeypad>(find.byType(CoreNumberKeypad))
          .isConfirmEnabled;
      // Release the save before asserting, so a failure cannot leave the
      // test waiting on it.
      database.writeGate!.complete();
      await tester.pumpAndSettle();

      expect(afterTyping, '7');
      expect(afterBackspace, '7');
      expect(focusedAfterPutBack, isTrue);
      expect(isConfirmEnabled, isFalse);
      expect(database.rows, hasLength(1));
    });

    testWidgets('the put-back key restores the opened value, totals it and '
        'drops focus', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await pumpFooter(tester, numberPad: quantityPad, fieldFocus: focus);
      await fillOthers(tester);
      await tester.tap(find.byKey(const Key('calc_key_nine')));
      await tester.pumpAndSettle();
      expect(quantity.text, '79');
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      await tester.tap(find.byKey(CoreNumberKeypad.clearButtonKey));
      await tester.pumpAndSettle();

      expect(quantity.text, '7');
      expect(find.text(r'$19.64'), findsOneWidget);
      expect(focus.hasFocus, isFalse);
      expect(database.rows, isEmpty);
    });
  });

  group('over a line already on the estimate', () {
    Future<void> openStoredLine(WidgetTester tester) async {
      fakeSupabase.addTableData(DatabaseConstants.costItemsTable, [
        CostItemTestDataMapFactory.createMaterialItemData(
          id: 'item-1',
          estimateId: 'estimate-1',
          itemName: 'Rebar',
          unitPrice: 100.0,
          quantity: 5.0,
          unit: 'pieces',
          itemTotalCost: 500.0,
          rateStatus: 'own_rate_confirmed',
        ),
      ]);
      await pumpFooter(tester);
      final items = await Modular.get<CostItemRepository>()
          .getCostItemsForEstimate('estimate-1');
      bloc.add(
        MaterialCostEditOpened(
          items.getRightOrNull()!.single as MaterialCostItem,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('keeps the edit wording while the quantity is cleared', (
      tester,
    ) async {
      await openStoredLine(tester);

      await fill(tester, quantity: '');

      expect(find.text('Changes this estimate'), findsOneWidget);
      expect(find.text('Adds to this estimate'), findsNothing);
      expect(find.text('Add to estimate'), findsNothing);
    });

    testWidgets('keeps the edit wording while the rate is cleared', (
      tester,
    ) async {
      await openStoredLine(tester);

      await fill(tester, rate: '');

      expect(find.text('Changes this estimate'), findsOneWidget);
      expect(find.text('Adds to this estimate'), findsNothing);
      expect(find.text('Add to estimate'), findsNothing);
    });
  });
}
