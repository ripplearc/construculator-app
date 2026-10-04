import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
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

  tearDown(() {
    fakeSupabase.reset();
  });

  YourRateEntry savedRate(EquipmentPricingMethod method, double amount) =>
      YourRateEntry(
        id: 'rate-1',
        companyId: 'company-1',
        itemName: 'Scissor lift — 19ft',
        category: CostItemType.equipment,
        rate: Money(amount: amount),
        savedAt: DateTime(2026, 1, 1),
        equipmentMethod: method,
      );

  Future<void> pumpSheet(WidgetTester tester, {YourRateEntry? entry}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
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
            ),
          ),
        ),
      ),
    );
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

      expect(find.text('Scissor lift — 19ft'), findsOneWidget);
      expect(find.text(r'$400.00 job · your default'), findsOneWidget);
      expect(find.byKey(SheetHeader.backButtonKey), findsOneWidget);
    });
  });
}
