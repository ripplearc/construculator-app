import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_add_to_estimate_footer.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_cost_items_database.dart';

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

  Future<void> pumpFooter(WidgetTester tester) async {
    bloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(bloc.close);
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
                        child: const MaterialAddToEstimateFooter(
                          estimateId: 'estimate-1',
                          estimateName: 'Bedroom 2',
                          estimateTotal: 2093.02,
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
  }) async {
    if (name != null) bloc.add(MaterialCostItemTypeChanged(name));
    if (quantity != null) bloc.add(MaterialQuantityUpdated(quantity));
    if (unit != null) bloc.add(MaterialUnitSelected(unit));
    if (rate != null) bloc.add(MaterialRateUpdated(rate));
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

    testWidgets('shows the line total and the estimate before and after', (
      tester,
    ) async {
      await pumpFooter(tester);
      await fillAll(tester);

      expect(find.text(r'$17.85'), findsOneWidget);
      expect(find.text(r'$2,110.87'), findsOneWidget);
      expect(find.textContaining('Bedroom 2'), findsOneWidget);
    });

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
      );

      expect(find.text(r'$1.01'), findsOneWidget);
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
}
