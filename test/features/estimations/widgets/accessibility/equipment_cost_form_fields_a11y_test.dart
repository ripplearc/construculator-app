import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/equipment_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  setUpAll(() {
    final fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  Widget makeWidget(ThemeData theme, {bool fromCostFile = false}) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<EquipmentCostFormBloc>(
          create: (_) => Modular.get<EquipmentCostFormBloc>(),
          child: EquipmentCostFormFields(fromCostFile: fromCostFile),
        ),
      ),
    );
  }

  group('EquipmentCostFormFields – accessibility', () {
    testWidgets(
      'a11y: rate field meets text contrast guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('rate_field')),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );

    testWidgets(
      'a11y: Day/Job toggle chips meet tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('day_method_chip')),
        );
      },
    );

    testWidgets(
      'a11y: equipment name error text meets contrast guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('equipment_name_field')),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
          setupAfterPump: (tester) async {
            await tester.enterText(
              find.byKey(const Key('equipment_name_field')),
              'x',
            );
            await tester.pump();
            await tester.enterText(
              find.byKey(const Key('equipment_name_field')),
              '',
            );
            await tester.pump();
          },
        );
      },
    );

    testWidgets(
      'a11y: collapsed delivery-fee row meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('delivery_fee_row')),
        );
      },
    );

    testWidgets(
      'a11y: delivery-fee Confirm link meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('delivery_fee_confirm_link')),
          setupAfterPump: (tester) async {
            // Base cost well above the fee below, so folding it doesn't
            // trigger the outsized-fee confirmation dialog.
            await tester.enterText(
              find.byKey(const Key('duration_field')),
              '2',
            );
            await tester.pump();
            await tester.enterText(find.byKey(const Key('rate_field')), '150');
            await tester.pump();
            await tester.tap(find.byKey(const Key('delivery_fee_row')));
            await tester.pump();
            await tester.enterText(
              find.byKey(const Key('delivery_fee_field')),
              '85',
            );
            await tester.pump();
            await tester.tap(find.byKey(const Key('equipment_name_field')));
            await tester.pumpAndSettle();
          },
        );
      },
    );
  });
}
