import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/equipment_add_to_estimate_footer.dart';
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
import '../../../../utils/fake_your_rates_database.dart';

void main() {
  late AppLocalizations l10n;

  final scissorLift = EquipmentCostItem(
    id: 'item-1',
    estimateId: 'estimate-1',
    itemName: 'Scissor lift',
    calculation: const {'daily_rate': 200.0, 'duration': 3.0},
    itemTotalCost: 685.0,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    currency: 'USD',
    pricingMethod: EquipmentPricingMethod.day,
    rateStatus: RateStatus.ownRateConfirmed,
    duration: 3.0,
    dailyRate: const Money(amount: 200.0),
    deliveryFee: const Money(amount: 85.0),
  );

  setUpAll(() {
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(
          supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
        ),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(FakeYourRatesDatabase());
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  tearDownAll(Modular.dispose);

  Future<void> pumpFooter(
    WidgetTester tester,
    List<EquipmentCostFormEvent> events,
  ) async {
    final bloc = Modular.get<EquipmentCostFormBloc>();
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<EquipmentCostFormBloc>.value(
            value: bloc,
            child: const EquipmentAddToEstimateFooter(
              estimateId: 'estimate-1',
              estimateName: 'Bedroom 2',
              estimateTotal: 2993.62,
            ),
          ),
        ),
      ),
    );
    events.forEach(bloc.add);
    await tester.pumpAndSettle();
  }

  String buttonLabel(WidgetTester tester) => tester
      .widget<CoreButton>(find.byKey(AddToEstimateFooter.buttonKey))
      .label!;

  final openScissorLift = EquipmentCostEditOpened(scissorLift);

  group('a line already on the estimate', () {
    testWidgets('offers to save the line, not to add it', (tester) async {
      await pumpFooter(tester, [openScissorLift]);

      expect(buttonLabel(tester), l10n.saveThisLineButton);
    });

    testWidgets('says there is no change yet before anything changes', (
      tester,
    ) async {
      await pumpFooter(tester, [openScissorLift]);

      expect(find.text(l10n.noChangeYetNote), findsOneWidget);
      expect(find.text(l10n.changesThisEstimateLabel), findsNothing);
      expect(find.text('+\$0.00'), findsOneWidget);
      expect(find.text(' total  \$2,993.62 →'), findsOneWidget);
      expect(find.text('\$2,993.62'), findsOneWidget);
    });

    testWidgets('shows a rise in the line as a plus amount and the new total', (
      tester,
    ) async {
      await pumpFooter(tester, [
        openScissorLift,
        const EquipmentDurationUpdatedEvent('4'),
      ]);

      expect(find.text('+\$200.00'), findsOneWidget);
      expect(find.textContaining('\$3,193.62'), findsOneWidget);
      expect(find.text(l10n.noChangeYetNote), findsNothing);
    });

    testWidgets(
      'shows a fall in the line as a minus amount and the new total',
      (tester) async {
        await pumpFooter(tester, [
          openScissorLift,
          const EquipmentDeliveryFeeUpdatedEvent(''),
        ]);

        expect(find.text('-\$85.00'), findsOneWidget);
        expect(find.textContaining('\$2,908.62'), findsOneWidget);
      },
    );

    testWidgets('says no change again when a field is put back', (
      tester,
    ) async {
      await pumpFooter(tester, [
        openScissorLift,
        const EquipmentDurationUpdatedEvent('4'),
        const EquipmentDurationUpdatedEvent('3'),
      ]);

      expect(find.text(l10n.noChangeYetNote), findsOneWidget);
    });

    testWidgets('keeps asking for what is missing, under the Changes title', (
      tester,
    ) async {
      await pumpFooter(tester, [
        openScissorLift,
        const EquipmentCostItemTypeChanged(''),
      ]);

      expect(buttonLabel(tester), l10n.enterEquipmentNameToContinueButton);
      expect(find.text(l10n.changesThisEstimateLabel), findsOneWidget);
      expect(find.text(l10n.addsToEstimateLabel), findsNothing);
    });
  });

  group('a new line', () {
    testWidgets('still offers to add it, under the Adds title', (tester) async {
      await pumpFooter(tester, [
        const EquipmentCostItemTypeChanged('Backhoe'),
        const EquipmentDurationUpdatedEvent('2'),
        const EquipmentRateUpdatedEvent('100'),
      ]);

      expect(find.byKey(AddToEstimateFooter.deleteButtonKey), findsNothing);
      expect(buttonLabel(tester), l10n.addToEstimateButton);
      expect(find.text(l10n.addsToEstimateLabel), findsOneWidget);
      expect(find.text(l10n.changesThisEstimateLabel), findsNothing);
    });
  });
}
