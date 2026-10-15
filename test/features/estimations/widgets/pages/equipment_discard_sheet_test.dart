import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/guarded_quick_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
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

  YourRateEntry savedRate(EquipmentPricingMethod method, double amount) =>
      YourRateEntry(
        id: 'rate-1',
        companyId: 'company-1',
        itemName: method == EquipmentPricingMethod.day
            ? 'Scissor lift — 19ft'
            : 'Dumpster — 30 yd',
        category: CostItemType.equipment,
        rate: Money(amount: amount),
        savedAt: DateTime(2026, 1, 1),
        equipmentMethod: method,
      );

  Future<void> openSheet(WidgetTester tester, {YourRateEntry? entry}) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final bloc = Modular.get<EquipmentCostFormBloc>();
    addTearDown(bloc.close);
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
                child: BlocProvider<EquipmentCostFormBloc>.value(
                  value: bloc,
                  child: CostItemFormScreen(
                    type: CostItemType.equipment,
                    estimationId: 'estimate-1',
                    router: FakeAppRouter(),
                    yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
                    clock: FakeClockImpl(),
                    presentAsSheet: true,
                    initialRateEntry: entry,
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

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pumpAndSettle();
  }

  Future<void> tapBack(WidgetTester tester) async {
    await tester.tap(find.byKey(SheetHeader.backButtonKey));
    await tester.pumpAndSettle();
  }

  group('closing the equipment sheet with something changed', () {
    testWidgets('a blank sheet closes at once on back', (tester) async {
      await openSheet(tester);

      await tapBack(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.text('New equipment cost'), findsNothing);
    });

    testWidgets('a typed name asks "Discard this line?" naming the item', (
      tester,
    ) async {
      await openSheet(tester);
      await enter(tester, 'equipment_name_field', 'Mini excavator');

      await tapBack(tester);

      expect(find.text(l10n.discardLineDialogTitle), findsOneWidget);
      expect(
        find.text(l10n.discardLineDialogBody('Mini excavator')),
        findsOneWidget,
      );
      expect(find.text(l10n.discardLineDiscardButton), findsOneWidget);
      expect(find.text(l10n.discardLineKeepEditingButton), findsOneWidget);
    });

    testWidgets('Keep editing stays on the sheet with the typed value', (
      tester,
    ) async {
      await openSheet(tester);
      await enter(tester, 'equipment_name_field', 'Mini excavator');
      await tapBack(tester);

      await tester.tap(find.byKey(ConfirmationDialog.primaryButtonKey));
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsNothing);
      expect(find.text('New equipment cost'), findsOneWidget);
      expect(find.text('Mini excavator'), findsOneWidget);
    });

    testWidgets('Discard closes the sheet and saves nothing', (tester) async {
      await openSheet(tester);
      await enter(tester, 'equipment_name_field', 'Mini excavator');
      await tapBack(tester);

      await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsNothing);
      expect(find.text('New equipment cost'), findsNothing);
      expect(fakeSupabase.getMethodCallsFor('insert'), isEmpty);
    });

    testWidgets('a tap on the dimmed background asks too', (tester) async {
      await openSheet(tester);
      await enter(tester, 'equipment_name_field', 'Mini excavator');

      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsOneWidget);
    });

    testWidgets('a swipe down on the handle asks too', (tester) async {
      await openSheet(tester);
      await enter(tester, 'equipment_name_field', 'Mini excavator');

      await tester.fling(
        find.byKey(GuardedQuickSheet.handleKey),
        const Offset(0, 300),
        1500,
      );
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsOneWidget);
    });

    testWidgets('closes without asking when a typed value is cleared again', (
      tester,
    ) async {
      await openSheet(tester);
      await enter(tester, 'equipment_name_field', 'Mini excavator');
      await enter(tester, 'equipment_name_field', '');

      await tapBack(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.text('New equipment cost'), findsNothing);
    });
  });

  group('closing a sheet opened from a saved rate', () {
    testWidgets('an untouched saved day rate closes at once', (tester) async {
      await openSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.day, 120),
      );

      await tapBack(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.text('Scissor lift — 19ft'), findsNothing);
    });

    testWidgets('typing the number of days asks, naming the saved item', (
      tester,
    ) async {
      await openSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.day, 120),
      );
      await enter(tester, 'duration_field', '3');

      await tapBack(tester);

      expect(find.text(l10n.discardLineDialogTitle), findsOneWidget);
      expect(
        find.text(l10n.discardLineDialogBody('Scissor lift — 19ft')),
        findsOneWidget,
      );
    });

    testWidgets('an untouched saved job price closes at once', (tester) async {
      await openSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.job, 400),
      );

      await tapBack(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.text('Dumpster — 30 yd'), findsNothing);
    });

    testWidgets('editing the recalled job price asks before discarding it', (
      tester,
    ) async {
      await openSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.job, 400),
      );
      await enter(tester, 'amount_field', '450');

      await tapBack(tester);

      expect(find.text(l10n.discardLineDialogTitle), findsOneWidget);
      expect(
        find.text(l10n.discardLineDialogBody('Dumpster — 30 yd')),
        findsOneWidget,
      );
    });

    testWidgets('putting the recalled job price back closes at once', (
      tester,
    ) async {
      await openSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.job, 400),
      );
      await enter(tester, 'amount_field', '450');
      await enter(tester, 'amount_field', '400');

      await tapBack(tester);

      expect(dialogTitle(), findsNothing);
      expect(find.text('Dumpster — 30 yd'), findsNothing);
    });

    testWidgets('Keep editing leaves the edited price in place', (
      tester,
    ) async {
      await openSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.job, 400),
      );
      await enter(tester, 'amount_field', '450');
      await tapBack(tester);

      await tester.tap(find.byKey(ConfirmationDialog.primaryButtonKey));
      await tester.pumpAndSettle();

      expect(dialogTitle(), findsNothing);
      expect(find.text('Dumpster — 30 yd'), findsOneWidget);
      expect(find.text('450'), findsOneWidget);
    });
  });
}
