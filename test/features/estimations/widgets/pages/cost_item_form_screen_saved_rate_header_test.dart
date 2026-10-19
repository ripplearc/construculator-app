import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
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

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    final clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
  });

  tearDown(() {
    fakeSupabase.reset();
  });

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

  Widget sheetApp({ThemeData? theme, YourRateEntry? entry}) {
    return MaterialApp(
      theme: theme ?? CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<EquipmentCostFormBloc>(
          create: (_) => Modular.get<EquipmentCostFormBloc>(),
          child: CostItemFormScreen(
            type: CostItemType.equipment,
            estimationId: 'test-estimation-id',
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
    );
  }

  Future<void> pumpSheet(WidgetTester tester, {YourRateEntry? entry}) async {
    await tester.pumpWidget(sheetApp(entry: entry));
    await tester.pumpAndSettle();
  }

  group('CostItemFormScreen – saved rate in the sheet header', () {
    testWidgets('a fresh sheet shows the New equipment cost title', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.text('New equipment cost'), findsOneWidget);
      expect(find.byKey(SheetHeader.backButtonKey), findsOneWidget);
    });

    testWidgets('a saved day rate moves the name and price into the header', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.day, 120),
      );

      expect(find.text('Scissor lift — 19ft'), findsOneWidget);
      expect(find.text(r'$120.00 /day · your default'), findsOneWidget);
      expect(find.text('New equipment cost'), findsNothing);
      expect(find.byKey(SheetHeader.backButtonKey), findsOneWidget);
      expect(find.byKey(const Key('recalled_rate_title')), findsNothing);
      expect(find.byKey(const Key('recalled_rate_subtitle')), findsNothing);
    });

    testWidgets('a saved job price moves the name and price into the header', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.job, 400),
      );

      expect(find.text('Dumpster — 30 yd'), findsOneWidget);
      expect(find.text(r'$400.00 job · your default'), findsOneWidget);
      expect(find.byKey(SheetHeader.backButtonKey), findsOneWidget);
    });

    testWidgets('typing a new amount keeps the saved price in the header', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.job, 400),
      );

      await tester.enterText(find.byKey(const Key('amount_field')), '450');
      await tester.pump();

      expect(find.text(r'$400.00 job · your default'), findsOneWidget);
      expect(find.text(r'$450.00 job · your default'), findsNothing);
      expect(find.byKey(const Key('equipment_name_field')), findsNothing);
    });

    testWidgets('clearing the amount keeps the saved price in the header', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        entry: savedRate(EquipmentPricingMethod.job, 400),
      );

      await tester.enterText(find.byKey(const Key('amount_field')), '');
      await tester.pump();

      expect(find.text(r'$400.00 job · your default'), findsOneWidget);
      expect(find.text(r'$0.00 job · your default'), findsNothing);
    });

    testWidgets('the very first frame already shows the saved name', (
      tester,
    ) async {
      await tester.pumpWidget(
        sheetApp(entry: savedRate(EquipmentPricingMethod.day, 120)),
      );

      expect(find.text('Scissor lift — 19ft'), findsOneWidget);
      expect(find.text('New equipment cost'), findsNothing);
      expect(find.byKey(const Key('equipment_name_field')), findsNothing);
    });
  });

  group('CostItemFormScreen – saved rate accessibility', () {
    testWidgets(
      'a11y: the sheet subtitle meets text contrast guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => sheetApp(
            theme: theme,
            entry: savedRate(EquipmentPricingMethod.day, 120),
          ),
          find.byKey(SheetHeader.subtitleKey),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );
  });
}
