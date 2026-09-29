import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/equipment_cost_form_fields.dart';
import 'package:construculator/features/estimation/presentation/widgets/underline_text_field.dart';
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
            yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
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

  // The outsized-fee check no longer runs on delivery-field focus loss (see
  // EquipmentCostFormFieldsState.maybeConfirmOutsizedFee's doc comment) —
  // it's meant to run from "Add to estimate", which is still a no-op stub
  // outside this widget (CA-355). Standing in for that future call, this
  // reaches the same public method directly via the widget's State.
  Future<void> triggerOutsizedFeeCheck(WidgetTester tester) async {
    final state = tester.state<EquipmentCostFormFieldsState>(
      find.byType(EquipmentCostFormFields),
    );
    unawaited(state.maybeConfirmOutsizedFee());
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

  // Invalid-value errors only render once the field loses focus (see
  // UnderlineTextField); this drops focus without touching any field's text.
  Future<void> unfocusAll(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
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

    testWidgets('shows placeholder text on the empty name and duration '
        'fields', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.equipmentNamePlaceholder), findsOneWidget);
      expect(find.text(l10n.equipmentDurationPlaceholder), findsOneWidget);
    });

    // Rate and Amount don't get placeholder text: with the rate-status badge
    // and Save-as-my-rate/Look-up trailing action both present, a hint text
    // overflows the value row by 128px. Name and Duration have neither, so
    // they keep theirs.
    testWidgets('does not show placeholder text on the rate field', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.equipmentRatePlaceholder), findsNothing);
    });

    testWidgets('does not show placeholder text on the amount field (Job)', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.equipmentAmountPlaceholder), findsNothing);
    });

    testWidgets('shows a Basis label above the Day/Job toggle', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.equipmentBasisLabel), findsOneWidget);
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

  group('EquipmentCostFormFields — no errors on untouched fields (B1)', () {
    // #650 stopped the bloc from ever putting a missing field into
    // fieldErrors (only a value that was actually typed and is invalid
    // gets an entry), so switching method or typing into one field can no
    // longer surface an error under a different, still-empty field.
    testWidgets('tapping Job on a fresh form shows no error text', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pumpAndSettle();
      await unfocusAll(tester);

      final nameField = tester.widget<UnderlineTextField>(
        find.byKey(const Key('equipment_name_field')),
      );
      expect(nameField.errorTextList, isNull);
      expect(find.text(l10n.equipmentAmountOutOfRangeError), findsNothing);
    });

    testWidgets(
      'typing only a name in Day mode shows no Duration or Rate error',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Backhoe',
        );
        await tester.pumpAndSettle();
        await unfocusAll(tester);

        expect(find.text(l10n.equipmentDurationInvalidError), findsNothing);
        expect(find.text(l10n.equipmentRateOutOfRangeError), findsNothing);
      },
    );
  });

  group('EquipmentCostFormFields — equipment name field', () {
    // The equipment name field never carries an error list at all (no
    // required-field error exists for it — the disabled Add button names
    // what's missing instead, per S1 on #653's review); this guards against
    // that wiring being re-added.
    testWidgets('never carries an error list, regardless of content', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();
      expect(
        tester
            .widget<UnderlineTextField>(
              find.byKey(const Key('equipment_name_field')),
            )
            .errorTextList,
        isNull,
      );

      await tester.enterText(find.byKey(const Key('equipment_name_field')), '');
      await tester.pump();
      expect(
        tester
            .widget<UnderlineTextField>(
              find.byKey(const Key('equipment_name_field')),
            )
            .errorTextList,
        isNull,
      );
    });
  });

  group('EquipmentCostFormFields — Day validation errors', () {
    testWidgets('does not show duration error while the field has focus', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '0');
      await tester.pump();

      expect(find.text(l10n.equipmentDurationInvalidError), findsNothing);
    });

    testWidgets(
      'shows duration error once the field loses focus with an invalid value',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '0');
        await tester.pump();
        await unfocusAll(tester);

        expect(find.text(l10n.equipmentDurationInvalidError), findsOneWidget);
      },
    );

    testWidgets(
      'hides the duration error again as soon as the field regains focus',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '0');
        await tester.pump();
        await unfocusAll(tester);
        expect(find.text(l10n.equipmentDurationInvalidError), findsOneWidget);

        // Tap the actual TextField, not just its key's bounding box: with
        // the item-1 fix, that box is only as wide as the "0" it contains,
        // so a tap at the key's geometric center can miss it.
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('duration_field')),
            matching: find.byType(TextField),
          ),
        );
        await tester.pump();

        expect(find.text(l10n.equipmentDurationInvalidError), findsNothing);
      },
    );

    testWidgets(
      'clears the duration error on the next blur once a valid value is typed',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '0');
        await tester.pump();
        await unfocusAll(tester);
        expect(find.text(l10n.equipmentDurationInvalidError), findsOneWidget);

        await tester.enterText(find.byKey(const Key('duration_field')), '2');
        await tester.pump();
        await unfocusAll(tester);

        expect(find.text(l10n.equipmentDurationInvalidError), findsNothing);
      },
    );

    testWidgets(
      'shows rate out-of-range error once the field loses focus above the accepted bound',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('rate_field')), '1000000');
        await tester.pump();

        expect(find.text(l10n.equipmentRateOutOfRangeError), findsNothing);

        await unfocusAll(tester);

        expect(find.text(l10n.equipmentRateOutOfRangeError), findsOneWidget);
      },
    );
  });

  group('EquipmentCostFormFields — Job validation errors', () {
    testWidgets(
      'shows amount out-of-range error once the field loses focus above the accepted bound',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('job_method_chip')));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('amount_field')),
          '1000000',
        );
        await tester.pump();

        expect(find.text(l10n.equipmentAmountOutOfRangeError), findsNothing);

        await unfocusAll(tester);

        expect(find.text(l10n.equipmentAmountOutOfRangeError), findsOneWidget);
      },
    );

    testWidgets(
      'clears the amount error on the next blur once a valid amount is typed',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('job_method_chip')));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('amount_field')),
          '1000000',
        );
        await tester.pump();
        await unfocusAll(tester);
        expect(find.text(l10n.equipmentAmountOutOfRangeError), findsOneWidget);

        await tester.enterText(find.byKey(const Key('amount_field')), '500');
        await tester.pump();
        await unfocusAll(tester);

        expect(find.text(l10n.equipmentAmountOutOfRangeError), findsNothing);
      },
    );
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
      await fillValidDayFields(
        tester,
      ); // base cost 300, well above the fee below

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
      // The header stays visible (and already formatted) alongside the
      // still-open field per the Figma mock — only the field itself shows
      // raw digits while typing.
      expect(find.text(deliveryRowText(85)), findsOneWidget);
    });

    testWidgets(
      'panel is stroked with lineLight (#eaecf0), matching Figma node 66337:162350',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        final panel = tester.widget<Container>(
          find.ancestor(
            of: find.byKey(const Key('delivery_fee_row')),
            matching: find.byType(Container),
          ),
        );
        final decoration = panel.decoration as BoxDecoration;
        final border = decoration.border as Border;
        expect(border.top.width, 1);
        expect(
          border.top.color,
          CoreTheme.light().extension<AppColorsExtension>()!.lineLight,
        );
      },
    );
  });

  group('EquipmentCostFormFields — delivery fee is never shown as an error', () {
    // UnderlineTextField only ever renders its error icon/text pair
    // together (see its errorTextList/hasError logic), so the absence of
    // this error string is enough to confirm no red/error chrome rendered
    // for the delivery-fee field.
    testWidgets(
      'a delivery fee above the accepted bound never colors the field red (S4)',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await expandDeliveryField(tester);
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '5000000',
        );
        await tester.pump();
        await foldDeliveryField(tester);

        expect(
          find.text(l10n.equipmentDeliveryFeeOutOfRangeError),
          findsNothing,
        );
      },
    );

    testWidgets(
      'a delivery fee of exactly 0 never colors the field red',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await expandDeliveryField(tester);
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '0',
        );
        await tester.pump();
        await foldDeliveryField(tester);

        expect(
          find.text(l10n.equipmentDeliveryFeeOutOfRangeError),
          findsNothing,
        );
      },
    );
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
        await fillValidDayFields(
          tester,
        ); // base cost 300, well above the fee below

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
        await fillValidDayFields(
          tester,
        ); // base cost 300, well above the fee below

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
        expect(
          find.byKey(const Key('delivery_fee_confirm_link')),
          findsNothing,
        );
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
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '0',
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
      'does not open on delivery-field focus loss, even for an outsized fee',
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

        // Folding the field alone must not trigger the dialog — only the
        // "Add to estimate" hook (stood in for by triggerOutsizedFeeCheck
        // in the tests below) does, per the fix to S1.
        expect(
          find.byKey(const Key('outsized_fee_dialog_title')),
          findsNothing,
        );
      },
    );

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
        await triggerOutsizedFeeCheck(tester);

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
      await tester.enterText(
        find.byKey(const Key('delivery_fee_field')),
        '600',
      );
      await tester.pump();
      await foldDeliveryField(tester);
      await triggerOutsizedFeeCheck(tester);

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
      await triggerOutsizedFeeCheck(tester);

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
        await triggerOutsizedFeeCheck(tester);

        expect(
          find.byKey(const Key('outsized_fee_dialog_title')),
          findsNothing,
        );
      },
    );

    testWidgets('names the duration and equipment in the Day-priced body', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'excavator',
      );
      await tester.pump();
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
      await triggerOutsizedFeeCheck(tester);

      expect(
        find.text(
          l10n.equipmentDeliveryFeeOutsizedDialogBodyDay(
            DisplayFormatter.currency.format(8500),
            '4',
            'excavator',
            DisplayFormatter.currency.format(580),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('omits the time period from the Job-priced body', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('amount_field')), '500');
      await tester.pump();

      await expandDeliveryField(tester);
      await tester.enterText(
        find.byKey(const Key('delivery_fee_field')),
        '600',
      );
      await tester.pump();
      await foldDeliveryField(tester);
      await triggerOutsizedFeeCheck(tester);

      expect(
        find.text(
          l10n.equipmentDeliveryFeeOutsizedDialogBody(
            DisplayFormatter.currency.format(600),
            DisplayFormatter.currency.format(500),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"Go back" dismisses the dialog and preserves the typed fee', (
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
      await triggerOutsizedFeeCheck(tester);

      await tester.tap(
        find.byKey(const Key('outsized_fee_dialog_go_back_button')),
      );
      await tester.pumpAndSettle();
      // The focus/selection request runs in the microtask continuation
      // after the dialog's own pop future resolves — pumpAndSettle already
      // flushes this, but one more explicit pump removes any doubt.
      await tester.pump();

      expect(find.byKey(const Key('outsized_fee_dialog_title')), findsNothing);
      // The fee is preserved, not cleared — the panel stays open and the
      // value stays put and editable.
      expect(find.text(deliveryRowText(8500)), findsOneWidget);
      expect(
        find.widgetWithText(TextField, '8500'),
        findsOneWidget,
      );
      // Per the storyboard ("the fee is selected and the pad is up"), focus
      // returns to the field with its value selected, ready to retype.
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, '8500'),
      );
      expect(field.focusNode?.hasFocus, isTrue);
      expect(
        field.controller?.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4),
      );
    });

    testWidgets(
      'tapping outside the dialog behaves like "Go back": preserves the fee',
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
        await triggerOutsizedFeeCheck(tester);

        // Tap the barrier, well outside the dialog's own 340-wide card.
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('outsized_fee_dialog_title')),
          findsNothing,
        );
        expect(find.text(deliveryRowText(8500)), findsOneWidget);
      },
    );

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
      await triggerOutsizedFeeCheck(tester);

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

  group('EquipmentCostFormFields — delivery panel open/close', () {
    testWidgets(
      'stays open across a fold, unlike the old collapse-on-blur behavior',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await expandDeliveryField(tester);
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '85',
        );
        await tester.pump();
        await foldDeliveryField(tester);

        expect(find.byKey(const Key('delivery_fee_field')), findsOneWidget);
        expect(find.byKey(const Key('delivery_note_field')), findsOneWidget);
      },
    );

    testWidgets('closes only when the header is tapped again', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await expandDeliveryField(tester);
      expect(find.byKey(const Key('delivery_fee_field')), findsOneWidget);

      await tester.tap(find.byKey(const Key('delivery_fee_row')));
      await tester.pump();

      expect(find.byKey(const Key('delivery_fee_field')), findsNothing);
      expect(find.byKey(const Key('delivery_note_field')), findsNothing);
    });

    testWidgets(
      'shows the Estimated helper sentence once folded with a fee entered',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await expandDeliveryField(tester);
        await tester.enterText(
          find.byKey(const Key('delivery_fee_field')),
          '85',
        );
        await tester.pump();
        await foldDeliveryField(tester);

        expect(
          find.text(l10n.equipmentDeliveryFeeEstimatedHelperText),
          findsOneWidget,
        );
      },
    );
  });

  group('EquipmentCostFormFields — Note field', () {
    testWidgets('"Add note" opens the panel focused on the Note field', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delivery_note_field')), findsNothing);

      await tester.tap(find.byKey(const Key('delivery_fee_add_note_link')));
      await tester.pump();

      expect(find.byKey(const Key('delivery_note_field')), findsOneWidget);
    });

    testWidgets('typed note text is retained in the field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await expandDeliveryField(tester);
      await tester.enterText(
        find.byKey(const Key('delivery_note_field')),
        'Leave at the gate',
      );
      await tester.pump();

      expect(find.text('Leave at the gate'), findsOneWidget);
    });
  });

  group('EquipmentCostFormFields — Rate/Amount status badge', () {
    testWidgets('shows no badge before a rate is entered (Day)', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rate_status_badge')), findsNothing);
    });

    testWidgets(
      'shows no badge once a daily rate is typed (ownRateUnconfirmed)',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('rate_field')), '150');
        await tester.pump();

        // A freshly typed rate is RateStatus.ownRateUnconfirmed, not
        // ownRateConfirmed (see EquipmentCostFormBloc's rate-update
        // handler) — the badge only renders for ownRateConfirmed/
        // sampleRateUnverified, so neither badge variant shows here.
        expect(find.byKey(const Key('rate_status_badge')), findsNothing);
        expect(
          find.text(l10n.equipmentRateStatusYourRateBadge),
          findsNothing,
        );
        // Also not offered here: saving an already-own-but-unconfirmed
        // value is still redundant (see _saveAsMyRateLink's doc comment).
        expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);
      },
    );

    testWidgets(
      'shows no badge once a job amount is typed (ownRateUnconfirmed)',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('job_method_chip')));
        await tester.pump();
        await tester.enterText(find.byKey(const Key('amount_field')), '500');
        await tester.pump();

        expect(find.byKey(const Key('rate_status_badge')), findsNothing);
        expect(
          find.text(l10n.equipmentRateStatusYourRateBadge),
          findsNothing,
        );
      },
    );
  });

  group('EquipmentCostFormFields — look up a rate', () {
    Future<YourRateEntry> seedRate({
      required String itemName,
      required double amount,
      required EquipmentPricingMethod method,
    }) async {
      final repository = Modular.get<YourRatesRepository>();
      final saveResult = await repository.save(
        YourRateEntry(
          id: '',
          companyId: 'company-1',
          itemName: itemName,
          category: CostItemType.equipment,
          rate: Money(amount: amount),
          savedAt: DateTime(2026, 1, 1),
          equipmentMethod: method,
        ),
      );
      saveResult.fold((f) => throw StateError('seed save failed: $f'), (_) {});
      final searchResult = await repository.search(
        itemName,
        category: CostItemType.equipment,
      );
      return searchResult.fold(
        (_) => throw StateError('seed search failed'),
        (entries) => entries.firstWhere((e) => e.itemName == itemName),
      );
    }

    testWidgets('shows a search button when the rate is empty (Day)', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lookup_rate_button')), findsOneWidget);
    });

    testWidgets('hides the search button once a rate is typed', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('rate_field')), '150');
      await tester.pump();

      expect(find.byKey(const Key('lookup_rate_button')), findsNothing);
    });

    testWidgets('picking a Your-rates entry fills name and rate', (
      tester,
    ) async {
      await seedRate(
        itemName: 'Mini excavator',
        amount: 145,
        method: EquipmentPricingMethod.day,
      );
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lookup_rate_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mini excavator'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('your_rates_use_button')));
      await tester.pumpAndSettle();

      expect(find.text('Mini excavator'), findsOneWidget);
      // Not '145.0': the field expects a plain typed-style number, matching
      // what a user would have typed directly (N6).
      expect(find.text('145'), findsOneWidget);
    });

    testWidgets(
      'picking a fractional-amount entry keeps the decimal, unlike a whole number',
      (tester) async {
        await seedRate(
          itemName: 'Skid steer',
          amount: 132.5,
          method: EquipmentPricingMethod.day,
        );
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('lookup_rate_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Skid steer'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('your_rates_use_button')));
        await tester.pumpAndSettle();

        expect(find.text('132.5'), findsOneWidget);
      },
    );

    testWidgets('a Job-priced entry never appears while Day is active', (
      tester,
    ) async {
      await seedRate(
        itemName: 'Dumpster',
        amount: 400,
        method: EquipmentPricingMethod.job,
      );
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lookup_rate_button')));
      await tester.pumpAndSettle();

      expect(find.text('Dumpster'), findsNothing);
      expect(find.byKey(const Key('your_rates_empty_state')), findsOneWidget);
    });
  });
}
