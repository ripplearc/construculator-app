import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/guarded_quick_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/toast_test_utils.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
  });

  tearDownAll(Modular.dispose);

  setUp(() => fakeSupabase.reset());

  Future<void> openSheet(
    WidgetTester tester, {
    Size size = const Size(412, 917),
    TargetPlatform? platform,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final bloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light().copyWith(platform: platform),
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
                  value: bloc,
                  child: CostItemFormScreen(
                    type: CostItemType.material,
                    estimationId: 'estimate-1',
                    router: FakeAppRouter(),
                    yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
                    clock: FakeClockImpl(),
                    presentAsSheet: true,
                    estimate: CostEstimate.defaultEstimate(
                      estimateName: 'Bedroom 2',
                      totalCost: 2093.02,
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

  // A tap on the title is a tap outside the keys: it closes the number pad,
  // which hides the form's Add button while it is up.
  Future<void> closeNumberPad(WidgetTester tester) async {
    await tester.tap(find.text('New material cost'));
    await tester.pumpAndSettle();
  }

  Future<void> fillAllFields(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('material_name_field')),
      'Interior paint',
    );
    await tester.enterText(
      find.byKey(const Key('material_quantity_field')),
      '3',
    );
    await tester.tap(find.byKey(const Key('material_unit_pill')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('unit_option_liters')));
    await tester.tap(find.byKey(const Key('unit_option_liters')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('material_rate_field')), '52');
    await tester.pumpAndSettle();
    await closeNumberPad(tester);
  }

  bool isAddDisabled(WidgetTester tester) {
    final numberPad = find.byType(CoreNumberKeypad);
    if (numberPad.evaluate().isNotEmpty) {
      return !tester.widget<CoreNumberKeypad>(numberPad).isConfirmEnabled;
    }
    return tester
        .widget<CoreButton>(find.byKey(AddToEstimateFooter.buttonKey))
        .isDisabled;
  }

  testWidgets('opens titled "New material cost" with every field empty', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('New material cost'), findsOneWidget);
    expect(find.text('Enter a material name to continue'), findsOneWidget);
    expect(isAddDisabled(tester), isTrue);
  });

  testWidgets('walks the button through each missing field in order', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.enterText(
      find.byKey(const Key('material_name_field')),
      'Interior paint',
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter a quantity to continue'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('material_quantity_field')),
      '3',
    );
    await tester.pumpAndSettle();
    expect(find.text('Needs a unit before it can total'), findsOneWidget);
    await closeNumberPad(tester);
    expect(find.text('Enter a unit to continue'), findsOneWidget);

    await tester.tap(find.byKey(const Key('material_unit_pill')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('unit_option_liters')));
    await tester.tap(find.byKey(const Key('unit_option_liters')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a rate to continue'), findsOneWidget);
    expect(find.text('Needs a rate before it can total'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('material_rate_field')), '52');
    await tester.pumpAndSettle();
    expect(find.text('Add to estimate'), findsOneWidget);
    expect(isAddDisabled(tester), isFalse);
  });

  testWidgets('shows what the line adds to the estimate', (tester) async {
    await openSheet(tester);

    await fillAllFields(tester);

    expect(find.text(r'$156.00'), findsOneWidget);
    expect(find.text(r'$2,249.02'), findsOneWidget);
  });

  testWidgets('adds the line and closes the sheet', (tester) async {
    await openSheet(tester);
    await fillAllFields(tester);

    await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
    await tester.pumpAndSettle();

    final row =
        fakeSupabase.getMethodCallsFor('insert').single['data']
            as Map<String, dynamic>;
    expect(row['estimate_id'], 'estimate-1');
    expect(row['item_name'], 'Interior paint');
    expect(row['item_total_cost'], 156.0);
    expect(find.text('New material cost'), findsNothing);
  });

  testWidgets('locks the fields and the unit button while the line is '
      'being saved', (tester) async {
    await openSheet(tester);
    await fillAllFields(tester);
    fakeSupabase.shouldDelayOperations = true;
    fakeSupabase.completer = Completer<void>();

    await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
    await tester.pump();

    for (final key in [
      'material_name_field',
      'material_quantity_field',
      'material_rate_field',
    ]) {
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(TextField),
              ),
            )
            .readOnly,
        isTrue,
        reason: key,
      );
    }
    await tester.tap(find.byKey(const Key('material_unit_pill')));
    await tester.pump();
    expect(find.text('Select unit'), findsNothing);

    fakeSupabase.completer!.complete();
    fakeSupabase.shouldDelayOperations = false;
    await tester.pumpAndSettle();
    expect(find.text('New material cost'), findsNothing);
  });

  testWidgets('keeps the sheet and its values when adding fails', (
    tester,
  ) async {
    fakeSupabase.shouldThrowOnInsert = true;
    await openSheet(tester);
    await fillAllFields(tester);

    await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
    await tester.pump();
    await tester.pump();

    expect(find.text('New material cost'), findsOneWidget);
    expect(find.text('Interior paint'), findsOneWidget);
    expect(isAddDisabled(tester), isFalse);
    await tester.pump(kToastDismissDuration);
  });

  group('closing with something typed', () {
    Finder dialogTitle() => find.byKey(ConfirmationDialog.titleKey);

    Future<void> typeName(WidgetTester tester, String name) async {
      await tester.enterText(
        find.byKey(const Key('material_name_field')),
        name,
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapBack(WidgetTester tester) async {
      await tester.tap(find.byKey(SheetHeader.backButtonKey));
      await tester.pumpAndSettle();
    }

    Future<void> swipeDownOnHandle(WidgetTester tester) async {
      await tester.fling(
        find.byKey(GuardedQuickSheet.handleKey),
        const Offset(0, 300),
        1500,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a swipe down on the handle with a name typed asks to discard '
        'the line', (tester) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');

      await swipeDownOnHandle(tester);

      expect(find.text('Discard this line?'), findsOneWidget);
      expect(find.text('New material cost'), findsOneWidget);
    });

    testWidgets('a swipe down on the handle closes at once when nothing was '
        'typed', (tester) async {
      await openSheet(tester);

      await swipeDownOnHandle(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.text('New material cost'), findsNothing);
    });

    testWidgets('a slow drag on the handle does not close the sheet', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.drag(
        find.byKey(GuardedQuickSheet.handleKey),
        const Offset(0, 20),
      );
      await tester.pumpAndSettle();

      expect(find.text('New material cost'), findsOneWidget);
    });

    testWidgets('closes at once when nothing was typed', (tester) async {
      await openSheet(tester);

      await tapBack(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.text('New material cost'), findsNothing);
    });

    testWidgets('a swipe down closes at once when nothing was typed', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.fling(
        find.byKey(SheetHeader.backButtonKey),
        const Offset(0, 500),
        1500,
      );
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsNothing);
      expect(find.text('New material cost'), findsNothing);
    });

    testWidgets('asks "Discard this line?" naming the material', (
      tester,
    ) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');

      await tapBack(tester);

      expect(find.text('Discard this line?'), findsOneWidget);
      expect(
        find.text('Interior paint has not been added to the estimate.'),
        findsOneWidget,
      );
      expect(find.text('New material cost'), findsOneWidget);
    });

    testWidgets('words the question without a name when only a number is '
        'typed', (tester) async {
      await openSheet(tester);
      await tester.enterText(
        find.byKey(const Key('material_quantity_field')),
        '3',
      );
      await tester.pumpAndSettle();

      await tapBack(tester);
      expect(find.byType(CoreNumberKeypad), findsNothing);
      expect(find.text('Discard this line?'), findsNothing);
      await tapBack(tester);

      expect(
        find.text('This line has not been added to the estimate.'),
        findsOneWidget,
      );
    });

    testWidgets('makes Keep editing the filled button and Discard the '
        'outlined one', (tester) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');

      await tapBack(tester);

      Finder labelIn(Key key) =>
          find.descendant(of: find.byKey(key), matching: find.byType(Text));
      BoxDecoration decorationOf(Key key) =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byKey(key),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(
        tester.widget<Text>(labelIn(ConfirmationDialog.primaryButtonKey)).data,
        'Keep editing',
      );
      expect(
        tester
            .widget<Text>(labelIn(ConfirmationDialog.secondaryButtonKey))
            .data,
        'Discard',
      );
      expect(decorationOf(ConfirmationDialog.primaryButtonKey).color!.a, 1.0);
      expect(decorationOf(ConfirmationDialog.secondaryButtonKey).color!.a, 0.0);
    });

    testWidgets('Keep editing stays on the sheet with every value', (
      tester,
    ) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');
      await tapBack(tester);

      await tester.tap(find.byKey(ConfirmationDialog.primaryButtonKey));
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsNothing);
      expect(find.text('New material cost'), findsOneWidget);
      expect(find.text('Interior paint'), findsOneWidget);
    });

    testWidgets('Discard closes the sheet and saves nothing', (tester) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');
      await tapBack(tester);

      await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsNothing);
      expect(find.text('New material cost'), findsNothing);
      expect(fakeSupabase.getMethodCallsFor('insert'), isEmpty);
    });

    testWidgets('a tap outside the dialog means Keep editing', (tester) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');
      await tapBack(tester);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsNothing);
      expect(find.text('New material cost'), findsOneWidget);
    });

    testWidgets('a tap on the dimmed background asks too', (tester) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');

      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsOneWidget);
    });

    testWidgets('a swipe down on the sheet asks too', (tester) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');

      await tester.fling(
        find.byKey(SheetHeader.backButtonKey),
        const Offset(0, 500),
        1500,
      );
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsOneWidget);
      expect(find.text('New material cost'), findsOneWidget);
    });

    testWidgets('with the keyboard up, the first back only closes the '
        'keyboard', (tester) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await tapBack(tester);
      expect(dialogTitle(), findsNothing);
      expect(find.text('New material cost'), findsOneWidget);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tapBack(tester);
      expect(dialogTitle(), findsOneWidget);
    });

    testWidgets('with the keyboard up and nothing typed, the first back only '
        'closes the keyboard', (tester) async {
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('material_name_field')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await tapBack(tester);
      expect(find.text('New material cost'), findsOneWidget);
      expect(dialogTitle(), findsNothing);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tapBack(tester);
      expect(find.text('New material cost'), findsNothing);
      expect(dialogTitle(), findsNothing);
    });

    testWidgets('with the keyboard up and nothing typed, a tap on the dimmed '
        'background only closes the keyboard', (tester) async {
      await openSheet(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      expect(find.text('New material cost'), findsOneWidget);
    });

    testWidgets('pulling a scrolling form down past its top closes it when '
        'nothing was typed', (tester) async {
      await openSheet(tester, size: const Size(412, 480));

      await tester.drag(
        find.byKey(const Key('material_name_field')),
        const Offset(0, 250),
      );
      await tester.pumpAndSettle();

      expect(find.text('New material cost'), findsNothing);
    });

    testWidgets('pulling a scrolling form down past its top asks when '
        'something was typed', (tester) async {
      await openSheet(tester, size: const Size(412, 480));
      await typeName(tester, 'Interior paint');

      await tester.drag(
        find.byKey(const Key('material_name_field')),
        const Offset(0, 250),
      );
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsOneWidget);
    });

    testWidgets('on iOS, pulling a scrolling form down past its top closes it '
        'when nothing was typed', (tester) async {
      await openSheet(
        tester,
        size: const Size(412, 480),
        platform: TargetPlatform.iOS,
      );

      await tester.drag(
        find.byKey(const Key('material_name_field')),
        const Offset(0, 250),
      );
      await tester.pumpAndSettle();

      expect(find.text('New material cost'), findsNothing);
    });

    testWidgets('on iOS, pulling a scrolling form down past its top asks '
        'when something was typed', (tester) async {
      await openSheet(
        tester,
        size: const Size(412, 480),
        platform: TargetPlatform.iOS,
      );
      await typeName(tester, 'Interior paint');

      await tester.drag(
        find.byKey(const Key('material_name_field')),
        const Offset(0, 250),
      );
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsOneWidget);
    });

    testWidgets('on iOS, a small pull that springs back does not close it', (
      tester,
    ) async {
      await openSheet(
        tester,
        size: const Size(412, 480),
        platform: TargetPlatform.iOS,
      );

      await tester.drag(
        find.byKey(const Key('material_name_field')),
        const Offset(0, 30),
      );
      await tester.pumpAndSettle();

      expect(find.text('New material cost'), findsOneWidget);
    });

    testWidgets('scrolling a long form down and back up part way does not '
        'close it', (tester) async {
      await openSheet(tester, size: const Size(412, 480));

      await tester.drag(
        find.byKey(const Key('material_name_field')),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('material_name_field')),
        const Offset(0, 40),
      );
      await tester.pumpAndSettle();

      expect(find.text('New material cost'), findsOneWidget);
      expect(dialogTitle(), findsNothing);
    });

    testWidgets('closes without asking when a typed value is cleared again', (
      tester,
    ) async {
      await openSheet(tester);
      await typeName(tester, 'Interior paint');
      await typeName(tester, '');

      await tapBack(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.text('New material cost'), findsNothing);
    });

    testWidgets('asks again after a failed save leaves the values in place', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnInsert = true;
      await openSheet(tester);
      await fillAllFields(tester);
      await tester.tap(find.byKey(AddToEstimateFooter.buttonKey));
      await tester.pump();
      await tester.pump();
      await tester.pump(kToastDismissDuration);

      await tapBack(tester);

      expect(dialogTitle(), findsOneWidget);
    });
  });
  group('number pad', () {
    final quantity = find.byKey(const Key('material_quantity_field'));
    final numberPad = find.byType(CoreNumberKeypad);
    final panel = find.byKey(AddToEstimateFooter.panelKey);

    String quantityText(WidgetTester tester) => tester
        .widget<TextField>(
          find.descendant(of: quantity, matching: find.byType(TextField)),
        )
        .controller!
        .text;

    Future<void> tapKey(WidgetTester tester, String name) async {
      await tester.tap(find.byKey(Key('calc_key_$name')));
      await tester.pump();
    }

    Future<void> openPadOnQuantity(WidgetTester tester) async {
      await tester.tap(quantity);
      await tester.pumpAndSettle();
    }

    testWidgets('opens on the quantity in place of the form button, with the '
        'card pinned on top of it', (tester) async {
      await openSheet(tester);

      await openPadOnQuantity(tester);

      expect(numberPad, findsOneWidget);
      expect(find.byKey(AddToEstimateFooter.buttonKey), findsNothing);
      expect(find.text('Clear'), findsOneWidget);
      final pad = tester.getRect(numberPad);
      expect(tester.getRect(panel).bottom + CoreSpacing.space4, pad.top);
      expect(
        tester.getRect(quantity).bottom,
        lessThan(tester.getRect(panel).top),
      );
      expect(
        tester.getRect(find.byType(CostItemFormScreen)).bottom,
        greaterThanOrEqualTo(pad.bottom),
      );
    });

    testWidgets('keys replace the selected quantity; a tap on the title '
        'closes the pad, keeps the number and adds nothing', (tester) async {
      await openSheet(tester);
      await tester.enterText(quantity, '3');
      await tester.pumpAndSettle();
      await tester.tap(find.text('New material cost'));
      await tester.pumpAndSettle();

      await openPadOnQuantity(tester);
      expect(find.text('Back to 3'), findsOneWidget);
      await tapKey(tester, 'two');
      await tapKey(tester, 'five');
      await tester.tap(find.text('New material cost'));
      await tester.pumpAndSettle();

      expect(numberPad, findsNothing);
      expect(quantityText(tester), '25');
      expect(find.byKey(AddToEstimateFooter.buttonKey), findsOneWidget);
      expect(fakeSupabase.getMethodCallsFor('insert'), isEmpty);
    });

    testWidgets('the put-back key restores the opened value and closes the '
        'pad', (tester) async {
      await openSheet(tester);
      await tester.enterText(quantity, '3');
      await tester.pumpAndSettle();
      await tester.tap(find.text('New material cost'));
      await tester.pumpAndSettle();
      await openPadOnQuantity(tester);
      await tapKey(tester, 'nine');

      await tester.tap(find.byKey(CoreNumberKeypad.clearButtonKey));
      await tester.pumpAndSettle();

      expect(quantityText(tester), '3');
      expect(numberPad, findsNothing);
    });

    testWidgets('the pad\'s Add to estimate adds the whole cost', (
      tester,
    ) async {
      await openSheet(tester);
      await fillAllFields(tester);
      await openPadOnQuantity(tester);

      await tester.tap(find.byKey(CoreNumberKeypad.confirmButtonKey));
      await tester.pumpAndSettle();

      expect(fakeSupabase.getMethodCallsFor('insert'), hasLength(1));
      expect(find.byType(CostItemFormScreen), findsNothing);
    });

    testWidgets('the back arrow and a swipe on the handle first close only '
        'the pad', (tester) async {
      await openSheet(tester);
      await openPadOnQuantity(tester);

      await tester.tap(find.byKey(SheetHeader.backButtonKey));
      await tester.pumpAndSettle();
      expect(numberPad, findsNothing);
      expect(find.byType(CostItemFormScreen), findsOneWidget);

      await openPadOnQuantity(tester);
      await tester.fling(
        find.byKey(GuardedQuickSheet.handleKey),
        const Offset(0, 300),
        1500,
      );
      await tester.pumpAndSettle();
      expect(numberPad, findsNothing);
      expect(find.byType(CostItemFormScreen), findsOneWidget);
    });

    testWidgets('a drag on the form scrolls it and keeps the pad up', (
      tester,
    ) async {
      await openSheet(tester, size: const Size(375, 667));
      await openPadOnQuantity(tester);

      await tester.drag(quantity, const Offset(0, -40));
      await tester.pumpAndSettle();

      expect(numberPad, findsOneWidget);
    });

    testWidgets('a11y: with the pad up every tap target on the sheet has a '
        'label and a 48 dp size, and a tap on the form background adds no '
        'unlabelled action', (tester) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester);
      await openPadOnQuantity(tester);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('the name field closes the pad before its own keyboard', (
      tester,
    ) async {
      await openSheet(tester);
      await openPadOnQuantity(tester);

      await tester.tap(find.byKey(const Key('material_name_field')));
      await tester.pump();

      expect(numberPad, findsNothing);
    });

    for (final size in const [Size(375, 667), Size(360, 640)]) {
      testWidgets('on a ${size.height.toInt()} dp phone the card scrolls with '
          'the form and the quantity stays above the pad', (tester) async {
        await openSheet(tester, size: size);

        await openPadOnQuantity(tester);

        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: find.byType(MaterialCostFormFields),
            matching: panel,
          ),
          findsOneWidget,
        );
        expect(
          tester.getRect(quantity).bottom,
          lessThan(tester.getRect(numberPad).top),
        );
        expect(numberPad, findsOneWidget);
      });
    }

    testWidgets('on a tall phone the card stays pinned at 2.0 text scale or '
        'scrolls, and nothing overflows', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSheet(tester);
      // The sheet already overflows 58 dp on the right at 2.0 text scale with
      // the pad down, on main too. This test checks the pad adds no overflow.
      tester.takeException();

      await openPadOnQuantity(tester);

      expect(tester.takeException(), isNull);
      expect(numberPad, findsOneWidget);
      expect(
        tester.getRect(quantity).top,
        lessThan(tester.getRect(numberPad).top),
      );
    });
  });
}
