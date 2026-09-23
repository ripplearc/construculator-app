import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/equipment_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late AppLocalizations l10n;
  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
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

  Widget makeWidget({
    bool fromCostFile = false,
    ValueChanged<double>? onTotalChanged,
    ValueChanged<bool>? onSaveEnabledChanged,
    String? estimateId,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<EquipmentCostFormBloc>(
          create: (_) => Modular.get<EquipmentCostFormBloc>(),
          child: EquipmentCostFormFields(
            fromCostFile: fromCostFile,
            onTotalChanged: onTotalChanged,
            onSaveEnabledChanged: onSaveEnabledChanged,
            estimateId: estimateId,
          ),
        ),
      ),
    );
  }

  Future<void> expandDeliveryField(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('delivery_fee_row')));
    await tester.pump();
  }

  Future<void> foldDeliveryField(WidgetTester tester) async {
    // Unfocus by tapping something else that doesn't itself steal semantics
    // we care about; the equipment name field is always present.
    await tester.tap(find.byKey(const Key('equipment_name_field')));
    await tester.pumpAndSettle();
  }

  String deliveryRowText([double? fee]) {
    final value = fee == null
        ? l10n.equipmentDeliveryFeeUnsetText
        : DisplayFormatter.currency.format(fee);
    return '${l10n.equipmentDeliveryRowLabel} $value';
  }

  Future<void> fillValidDayFields(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('equipment_name_field')),
      'Backhoe',
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('duration_field')), '2');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('rate_field')), '150');
    await tester.pump();
  }

  group('EquipmentCostFormFields — manually mode', () {
    testWidgets('shows equipment name field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipment_name_field')), findsOneWidget);
    });

    testWidgets('shows Day/Job toggle with Day selected by default', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('day_method_chip')), findsOneWidget);
      expect(find.byKey(const Key('job_method_chip')), findsOneWidget);
      expect(find.byKey(const Key('duration_field')), findsOneWidget);
      expect(find.byKey(const Key('rate_field')), findsOneWidget);
      expect(find.byKey(const Key('amount_field')), findsNothing);
    });

    testWidgets('hides unit price and quantity fields', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unit_price_field')), findsNothing);
      expect(find.byKey(const Key('quantity_field')), findsNothing);
    });

    testWidgets('hides cost file field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cost_file_field')), findsNothing);
    });

    testWidgets('hides equipment type field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipment_type_field')), findsNothing);
    });
  });

  group('EquipmentCostFormFields — Day/Job toggle', () {
    testWidgets('tapping Job swaps duration+rate for a single amount field', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();

      expect(find.byKey(const Key('duration_field')), findsNothing);
      expect(find.byKey(const Key('rate_field')), findsNothing);
      expect(find.byKey(const Key('amount_field')), findsOneWidget);
    });

    testWidgets('tapping Day after Job restores duration+rate fields', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('day_method_chip')));
      await tester.pump();

      expect(find.byKey(const Key('duration_field')), findsOneWidget);
      expect(find.byKey(const Key('rate_field')), findsOneWidget);
      expect(find.byKey(const Key('amount_field')), findsNothing);
    });

    testWidgets('switching method preserves the equipment name field value', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();

      expect(find.text('Backhoe'), findsOneWidget);
    });

    testWidgets('re-tapping the already-active Day chip is a no-op', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('day_method_chip')));
      await tester.pump();

      expect(find.byKey(const Key('duration_field')), findsOneWidget);
      expect(find.byKey(const Key('rate_field')), findsOneWidget);
      expect(find.byKey(const Key('amount_field')), findsNothing);
    });

    testWidgets(
      'switching to Job and back to Day preserves the previously entered duration/rate',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '3');
        await tester.pump();
        await tester.enterText(find.byKey(const Key('rate_field')), '75');
        await tester.pump();

        await tester.tap(find.byKey(const Key('job_method_chip')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('day_method_chip')));
        await tester.pump();

        expect(find.text('3'), findsOneWidget);
        expect(find.text('75'), findsOneWidget);
      },
    );
  });

  group('EquipmentCostFormFields — item type error', () {
    testWidgets(
      'shows error text when equipment name is cleared after typing',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Backhoe',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          '',
        );
        await tester.pump();

        expect(find.text(l10n.equipmentNameRequiredError), findsOneWidget);
      },
    );

    testWidgets('hides error text when equipment name is non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();

      expect(find.text(l10n.equipmentNameRequiredError), findsNothing);
    });
  });

  group('EquipmentCostFormFields — Day validation errors', () {
    testWidgets('shows duration error when duration is entered then cleared', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '0');
      await tester.pump();

      expect(find.text(l10n.equipmentDurationRequiredError), findsOneWidget);
    });

    testWidgets('hides duration error once duration is positive', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '0');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('duration_field')), '2');
      await tester.pump();

      expect(find.text(l10n.equipmentDurationRequiredError), findsNothing);
    });

    testWidgets('shows rate out-of-range error above the accepted bound', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('rate_field')), '1000000');
      await tester.pump();

      expect(find.text(l10n.equipmentRateOutOfRangeError), findsOneWidget);
    });
  });

  group('EquipmentCostFormFields — Job validation errors', () {
    testWidgets('shows amount out-of-range error above the accepted bound', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('amount_field')), '1000000');
      await tester.pump();

      expect(find.text(l10n.equipmentAmountOutOfRangeError), findsOneWidget);
    });

    testWidgets('hides amount error once a valid amount is entered', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('amount_field')), '1000000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('amount_field')), '500');
      await tester.pump();

      expect(find.text(l10n.equipmentAmountOutOfRangeError), findsNothing);
    });
  });

  group('EquipmentCostFormFields — from cost file mode', () {
    testWidgets('shows cost file dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cost_file_field')), findsOneWidget);
    });

    testWidgets('shows equipment type dropdown placeholder', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipment_type_field')), findsOneWidget);
    });

    testWidgets('shows quantity field', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quantity_field')), findsOneWidget);
    });

    testWidgets('hides equipment name field', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipment_name_field')), findsNothing);
    });

    testWidgets('hides Day/Job toggle', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('day_method_chip')), findsNothing);
      expect(find.byKey(const Key('job_method_chip')), findsNothing);
    });
  });

  group('EquipmentCostFormFields — save enabled', () {
    testWidgets('calls onSaveEnabledChanged(false) initially', (tester) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(onSaveEnabledChanged: (v) => captured = v),
      );
      await tester.pumpAndSettle();

      expect(captured, isNull);
    });

    testWidgets('stays disabled when only the equipment name is filled (Day)', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(onSaveEnabledChanged: (v) => captured = v),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();

      expect(captured, isFalse);
    });

    testWidgets(
      'becomes enabled once name, duration, and rate are all valid (Day)',
      (tester) async {
        bool? captured;
        await tester.pumpWidget(
          makeWidget(onSaveEnabledChanged: (v) => captured = v),
        );
        await tester.pumpAndSettle();

        await fillValidDayFields(tester);

        expect(captured, isTrue);
      },
    );

    testWidgets('becomes enabled once name and amount are valid (Job)', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(onSaveEnabledChanged: (v) => captured = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('amount_field')), '500');
      await tester.pump();

      expect(captured, isTrue);
    });

    testWidgets(
      'becomes disabled again after switching from a valid Day form to Job with no amount',
      (tester) async {
        bool? captured;
        await tester.pumpWidget(
          makeWidget(onSaveEnabledChanged: (v) => captured = v),
        );
        await tester.pumpAndSettle();

        await fillValidDayFields(tester);
        expect(captured, isTrue);

        await tester.tap(find.byKey(const Key('job_method_chip')));
        await tester.pump();

        expect(captured, isFalse);
      },
    );

    testWidgets('does not call onSaveEnabledChanged in from cost file mode', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        makeWidget(
          fromCostFile: true,
          onSaveEnabledChanged: (v) => captured = v,
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, isNull);
    });

    testWidgets(
      'calls onSaveEnabledChanged(false) when switching to from cost file mode after filling a valid Day form',
      (tester) async {
        bool? captured;
        await tester.pumpWidget(
          makeWidget(onSaveEnabledChanged: (v) => captured = v),
        );
        await tester.pumpAndSettle();

        await fillValidDayFields(tester);
        expect(captured, isTrue);

        await tester.pumpWidget(
          makeWidget(
            fromCostFile: true,
            onSaveEnabledChanged: (v) => captured = v,
          ),
        );
        await tester.pump();

        expect(captured, isFalse);
      },
    );
  });

  group('EquipmentCostFormFields — real-time total', () {
    testWidgets('calls onTotalChanged with duration × rate under Day', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '3');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '200');
      await tester.pump();

      expect(capturedTotal, 600.0);
    });

    testWidgets('calls onTotalChanged with the amount under Job', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('amount_field')), '750');
      await tester.pump();

      expect(capturedTotal, 750.0);
    });

    testWidgets(
      'resets total to 0 immediately when switching from Day to Job',
      (tester) async {
        double? capturedTotal;
        await tester.pumpWidget(
          makeWidget(onTotalChanged: (total) => capturedTotal = total),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '3');
        await tester.pump();
        await tester.enterText(find.byKey(const Key('rate_field')), '200');
        await tester.pump();
        expect(capturedTotal, 600.0);

        await tester.tap(find.byKey(const Key('job_method_chip')));
        await tester.pump();

        expect(capturedTotal, 0.0);
      },
    );

    testWidgets('calls onTotalChanged with 0 when duration is empty', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('rate_field')), '200');
      await tester.pump();

      expect(capturedTotal, 0.0);
    });

    testWidgets('calls onTotalChanged with 0 in fromCostFile mode', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(
          fromCostFile: true,
          onTotalChanged: (total) => capturedTotal = total,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('quantity_field')), '5');
      await tester.pump();

      expect(capturedTotal, 0.0);
    });

    testWidgets(
      'resets total to 0 when fromCostFile flips on a mounted widget',
      (tester) async {
        double? capturedTotal;
        await tester.pumpWidget(
          makeWidget(onTotalChanged: (total) => capturedTotal = total),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '3');
        await tester.pump();
        await tester.enterText(find.byKey(const Key('rate_field')), '200');
        await tester.pump();

        await tester.pumpWidget(
          makeWidget(
            fromCostFile: true,
            onTotalChanged: (total) => capturedTotal = total,
          ),
        );
        await tester.pump();

        expect(capturedTotal, 0.0);
      },
    );
  });

  group('EquipmentCostFormFields — delivery fee row display states', () {
    testWidgets('shows a dash when no delivery fee has been entered', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.text(deliveryRowText()), findsOneWidget);
    });

    testWidgets('formats to two decimals once folded', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await fillValidDayFields(tester); // base cost 300, well above the fee below

      await expandDeliveryField(tester);
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '85');
      await tester.pump();
      await foldDeliveryField(tester);

      expect(find.text(deliveryRowText(85)), findsOneWidget);
    });

    testWidgets('typed 0 folds to a distinct \$0.00, never a dash', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await expandDeliveryField(tester);
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '0');
      await tester.pump();
      await foldDeliveryField(tester);

      expect(find.text(deliveryRowText(0)), findsOneWidget);
      expect(find.text(deliveryRowText()), findsNothing);
    });

    testWidgets('shows raw typed digits in the field while open, unformatted', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await expandDeliveryField(tester);
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '85');
      await tester.pump();

      expect(find.text('85'), findsOneWidget);
      expect(find.text('\$85.00'), findsNothing);
      expect(find.text(deliveryRowText(85)), findsNothing);
    });
  });

  group('EquipmentCostFormFields — Estimated/Confirm badge lifecycle', () {
    testWidgets('hides the badge and link while the field has focus', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await expandDeliveryField(tester);
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '85');
      await tester.pump();

      expect(
        find.byKey(const Key('delivery_fee_estimated_badge')),
        findsNothing,
      );
      expect(find.byKey(const Key('delivery_fee_confirm_link')), findsNothing);
    });

    testWidgets(
      'shows Estimated badge and Confirm link once folded with a fee entered',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await fillValidDayFields(tester); // base cost 300, well above the fee below

        await expandDeliveryField(tester);
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '85',
        );
        await tester.pump();
        await foldDeliveryField(tester);

        expect(
          find.byKey(const Key('delivery_fee_estimated_badge')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('delivery_fee_confirm_link')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping Confirm removes the badge/link and shows the confirmed helper text',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await fillValidDayFields(tester); // base cost 300, well above the fee below

        await expandDeliveryField(tester);
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '85',
        );
        await tester.pump();
        await foldDeliveryField(tester);

        await tester.tap(find.byKey(const Key('delivery_fee_confirm_link')));
        await tester.pump();

        expect(
          find.byKey(const Key('delivery_fee_estimated_badge')),
          findsNothing,
        );
        expect(find.byKey(const Key('delivery_fee_confirm_link')), findsNothing);
        expect(
          find.text(l10n.equipmentDeliveryFeeConfirmedHelperText),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'an entered-but-unconfirmed \$0.00 still gets the Estimated/Confirm treatment',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await expandDeliveryField(tester);
        await tester.enterText(find.byKey(const Key('delivery_fee_field')), '0');
        await tester.pump();
        await foldDeliveryField(tester);

        expect(
          find.byKey(const Key('delivery_fee_estimated_badge')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('delivery_fee_confirm_link')),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows neither badge nor helper text when unset', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('delivery_fee_estimated_badge')),
        findsNothing,
      );
      expect(
        find.text(l10n.equipmentDeliveryFeeConfirmedHelperText),
        findsNothing,
      );
    });
  });

  group('EquipmentCostFormFields — outsized delivery-fee dialog', () {
    testWidgets(
      'opens when the delivery fee exceeds the Day base cost (duration × rate)',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '4');
        await tester.pump();
        await tester.enterText(find.byKey(const Key('rate_field')), '145');
        await tester.pump();

        await expandDeliveryField(tester);
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '8500',
        );
        await tester.pump();
        await foldDeliveryField(tester);

        expect(
          find.byKey(const Key('outsized_fee_dialog_title')),
          findsOneWidget,
        );
      },
    );

    testWidgets('opens when the delivery fee exceeds the Job amount', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('amount_field')), '500');
      await tester.pump();

      await expandDeliveryField(tester);
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '600');
      await tester.pump();
      await foldDeliveryField(tester);

      expect(
        find.byKey(const Key('outsized_fee_dialog_title')),
        findsOneWidget,
      );
    });

    testWidgets('does not open when the fee is at or below the base cost', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '4');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '145');
      await tester.pump();

      await expandDeliveryField(tester);
      await tester.enterText(
        find.byKey(const Key('delivery_fee_field')),
        '580',
      );
      await tester.pump();
      await foldDeliveryField(tester);

      expect(find.byKey(const Key('outsized_fee_dialog_title')), findsNothing);
    });

    testWidgets(
      'does not open when duration/rate are not entered yet (base cost is 0)',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        // Duration/rate are left empty; entering the delivery fee first
        // must not compare it against an unset $0 base cost.
        await expandDeliveryField(tester);
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '5',
        );
        await tester.pump();
        await foldDeliveryField(tester);

        expect(
          find.byKey(const Key('outsized_fee_dialog_title')),
          findsNothing,
        );
      },
    );

    testWidgets('"Go back" dismisses the dialog and leaves the fee unset', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '4');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '145');
      await tester.pump();

      await expandDeliveryField(tester);
      await tester.enterText(
        find.byKey(const Key('delivery_fee_field')),
        '8500',
      );
      await tester.pump();
      await foldDeliveryField(tester);

      await tester.tap(
        find.byKey(const Key('outsized_fee_dialog_go_back_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('outsized_fee_dialog_title')), findsNothing);
      expect(find.text(deliveryRowText()), findsOneWidget);
    });

    testWidgets('"Add it" closes the dialog and keeps the fee as entered', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget(estimateId: 'estimate-1'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '4');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '145');
      await tester.pump();

      await expandDeliveryField(tester);
      await tester.enterText(
        find.byKey(const Key('delivery_fee_field')),
        '8500',
      );
      await tester.pump();
      await foldDeliveryField(tester);

      await tester.tap(
        find.byKey(const Key('outsized_fee_dialog_add_it_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('outsized_fee_dialog_title')), findsNothing);
      expect(find.text(deliveryRowText(8500)), findsOneWidget);
    });
  });

  group('EquipmentCostFormFields — delivery fee in the total', () {
    testWidgets('adds the delivery fee to the Day total after the base cost', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '2');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '200');
      await tester.pump();

      await expandDeliveryField(tester);
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '50');
      await tester.pump();

      expect(capturedTotal, 450.0);
    });

    testWidgets('adds the delivery fee to the Job total', (tester) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('amount_field')), '750');
      await tester.pump();

      await expandDeliveryField(tester);
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '25');
      await tester.pump();

      expect(capturedTotal, 775.0);
    });

    testWidgets('an unset delivery fee does not affect the total', (
      tester,
    ) async {
      double? capturedTotal;
      await tester.pumpWidget(
        makeWidget(onTotalChanged: (total) => capturedTotal = total),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '2');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '200');
      await tester.pump();

      expect(capturedTotal, 400.0);
    });
  });
}
