import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
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
              onPressed: () => CoreQuickSheet.show<void>(
                context: context,
                enableDrag: false,
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
  }

  bool isAddDisabled(WidgetTester tester) => tester
      .widget<CoreButton>(find.byKey(AddToEstimateFooter.buttonKey))
      .isDisabled;

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

      expect(
        tester
            .widget<CoreButton>(find.byKey(ConfirmationDialog.primaryButtonKey))
            .label,
        'Keep editing',
      );
      expect(
        tester
            .widget<CoreButton>(
              find.byKey(ConfirmationDialog.secondaryButtonKey),
            )
            .label,
        'Discard',
      );
      expect(
        tester
            .widget<CoreButton>(find.byKey(ConfirmationDialog.primaryButtonKey))
            .variant,
        CoreButtonVariant.primary,
      );
      expect(
        tester
            .widget<CoreButton>(
              find.byKey(ConfirmationDialog.secondaryButtonKey),
            )
            .variant,
        CoreButtonVariant.secondary,
      );
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
}
