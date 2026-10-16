import 'dart:async';

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

  tearDownAll(() {
    Modular.dispose();
  });

  Future<void> pumpFooter(
    WidgetTester tester,
    List<EquipmentCostFormEvent> events,
  ) async {
    final bloc = Modular.get<EquipmentCostFormBloc>();
    addTearDown(() => unawaited(bloc.close()));
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

  const name = EquipmentCostItemTypeChanged('Backhoe');
  const switchToJob = EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job);

  group('what the button asks for', () {
    testWidgets('a name first', (tester) async {
      await pumpFooter(tester, []);

      expect(buttonLabel(tester), l10n.enterEquipmentNameToContinueButton);
    });

    testWidgets('a duration', (tester) async {
      await pumpFooter(tester, [name]);

      expect(buttonLabel(tester), l10n.enterDurationToContinueButton);
    });

    testWidgets('a duration above zero', (tester) async {
      await pumpFooter(tester, [
        name,
        const EquipmentDurationUpdatedEvent('0'),
      ]);

      expect(buttonLabel(tester), l10n.fixDurationToContinueButton);
    });

    testWidgets('a duration that fits', (tester) async {
      await pumpFooter(tester, [
        name,
        const EquipmentDurationUpdatedEvent('999999999999'),
      ]);

      expect(buttonLabel(tester), l10n.fixDurationToContinueButton);
    });

    testWidgets('a rate', (tester) async {
      await pumpFooter(tester, [
        name,
        const EquipmentDurationUpdatedEvent('2'),
      ]);

      expect(buttonLabel(tester), l10n.enterRateToContinueButton);
    });

    testWidgets('a rate that fits', (tester) async {
      await pumpFooter(tester, [
        name,
        const EquipmentDurationUpdatedEvent('2'),
        const EquipmentRateUpdatedEvent('5000000'),
      ]);

      expect(buttonLabel(tester), l10n.fixRateToContinueButton);
    });

    testWidgets('an amount', (tester) async {
      await pumpFooter(tester, [name, switchToJob]);

      expect(buttonLabel(tester), l10n.enterAmountToContinueButton);
    });

    testWidgets('an amount that fits', (tester) async {
      await pumpFooter(tester, [
        name,
        switchToJob,
        const EquipmentRateUpdatedEvent('5000000'),
      ]);

      expect(buttonLabel(tester), l10n.fixAmountToContinueButton);
    });

    testWidgets('nothing more when the line is complete', (tester) async {
      await pumpFooter(tester, [
        name,
        const EquipmentDurationUpdatedEvent('2'),
        const EquipmentRateUpdatedEvent('100'),
      ]);

      expect(buttonLabel(tester), l10n.addToEstimateButton);
    });
  });
}
