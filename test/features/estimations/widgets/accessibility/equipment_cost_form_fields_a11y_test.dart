import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
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
  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    fakeSupabase.reset();
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
          child: EquipmentCostFormFields(
            fromCostFile: fromCostFile,
            yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
            clock: FakeClockImpl(),
          ),
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
      'a11y: equipment name field meets tap target and label guidelines in '
      'both themes (it never shows an error, per product decision)',
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
      'a11y: duration error text meets contrast guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('duration_field')),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
          setupAfterPump: (tester) async {
            await tester.enterText(
              find.byKey(const Key('duration_field')),
              '0',
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
      'a11y: look-up-a-rate button meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('lookup_rate_button')),
        );
      },
    );

    testWidgets(
      'a11y: expanded delivery-fee field meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('delivery_fee_field')),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
          setupAfterPump: (tester) async {
            // The small a11y test viewport doesn't show the delivery row
            // without scrolling — ensure it's in view before tapping.
            await tester.ensureVisible(
              find.byKey(const Key('delivery_fee_row')),
            );
            // The delivery panel stays open across a fold (see
            // EquipmentCostFormFields._deliveryExpanded's doc comment), and
            // this helper reuses the same widget State across the
            // light/dark theme loop — so on the second theme, the field may
            // already be open from the first theme's run. Only tap to open
            // it if it isn't already.
            if (find
                .byKey(const Key('delivery_fee_field'))
                .evaluate()
                .isEmpty) {
              await tester.tap(find.byKey(const Key('delivery_fee_row')));
              await tester.pump();
            }
            await tester.enterText(
              find.byKey(const Key('delivery_fee_field')),
              '85',
            );
            await tester.pump();
          },
        );
      },
    );

    // Opens the label-collision dialog (_EntryLabelDialog) so its 3
    // interactive elements — the text field and the two buttons — get their
    // own a11y coverage, matching the rest of this file's one-target-per-test
    // granularity. Seeds a colliding "Backhoe" entry first so tapping
    // "Save as my rate" triggers YourRatesSaveCollision instead of a plain
    // save.
    Future<void> openEntryLabelDialog(WidgetTester tester) async {
      // The theme loop in expectMeetsTapTargetAndLabelGuidelinesForEachTheme
      // reuses the same widget State across both pumps (see the
      // delivery-fee Confirm-link test above), so the dialog opened on the
      // first theme may still be showing on the second — only open it once.
      if (find.byKey(const Key('entry_label_dialog_title')).evaluate().isNotEmpty) {
        return;
      }
      final repository = Modular.get<YourRatesRepository>();
      await repository.save(
        YourRateEntry(
          id: '',
          companyId: '',
          itemName: 'Backhoe',
          category: CostItemType.equipment,
          rate: const Money(amount: 100),
          savedAt: DateTime(2026, 1, 1),
          equipmentMethod: EquipmentPricingMethod.day,
          entryLabel: 'Supplier A',
        ),
      );
      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '150');
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'a11y: entry-label field meets text contrast guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('entry_label_field')),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
          setupAfterPump: openEntryLabelDialog,
        );
      },
    );

    testWidgets(
      'a11y: entry-label dialog Cancel button meets tap target and label '
      'guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('entry_label_dialog_cancel_button')),
          setupAfterPump: openEntryLabelDialog,
        );
      },
    );

    testWidgets(
      'a11y: entry-label dialog Save button meets tap target and label '
      'guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('entry_label_dialog_save_button')),
          setupAfterPump: openEntryLabelDialog,
        );
      },
    );
  });
}
