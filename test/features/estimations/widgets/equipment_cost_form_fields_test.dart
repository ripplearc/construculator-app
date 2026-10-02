import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/choice_chip_toggle.dart';
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
    CoreToast.disableTimers();
    l10n = lookupAppLocalizations(const Locale('en'));
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.dispose();
    CoreToast.enableTimers();
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
            clock: FakeClockImpl(),
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
      expect(
        tester.widget<ChoiceChipToggle>(
          find.byKey(const Key('day_method_chip')),
        ),
        isA<ChoiceChipToggle>().having(
          (c) => c.selected.value,
          'selected',
          true,
        ),
      );
      expect(
        tester.widget<ChoiceChipToggle>(
          find.byKey(const Key('job_method_chip')),
        ),
        isA<ChoiceChipToggle>().having(
          (c) => c.selected.value,
          'selected',
          false,
        ),
      );
    });

    testWidgets('re-tapping the already-active Job chip is a no-op', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();

      expect(find.byKey(const Key('amount_field')), findsOneWidget);
      expect(
        tester.widget<ChoiceChipToggle>(
          find.byKey(const Key('job_method_chip')),
        ),
        isA<ChoiceChipToggle>().having(
          (c) => c.selected.value,
          'selected',
          true,
        ),
      );
      expect(
        tester.widget<ChoiceChipToggle>(
          find.byKey(const Key('day_method_chip')),
        ),
        isA<ChoiceChipToggle>().having(
          (c) => c.selected.value,
          'selected',
          false,
        ),
      );
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

        expect(find.text(l10n.equipmentDurationNotPositiveError), findsNothing);
        expect(find.text(l10n.equipmentRateOutOfRangeError), findsNothing);
      },
    );
  });

  group('EquipmentCostFormFields — equipment name field', () {
    // The equipment name field never carries an error list at all (no
    // required-field error exists for it; the disabled Add button names what
    // is missing instead). This guards against that wiring being re-added.
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

      expect(find.text(l10n.equipmentDurationNotPositiveError), findsNothing);
    });

    testWidgets(
      'shows duration error once the field loses focus with an invalid value',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '0');
        await tester.pump();
        await unfocusAll(tester);

        expect(
          find.text(l10n.equipmentDurationNotPositiveError),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows the half-day-step error once the field loses focus with a '
      'positive non-half-day value',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '1.3');
        await tester.pump();
        await unfocusAll(tester);

        expect(
          find.text(l10n.equipmentDurationNotHalfDayError),
          findsOneWidget,
        );
        expect(find.text(l10n.equipmentDurationNotPositiveError), findsNothing);
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
        expect(
          find.text(l10n.equipmentDurationNotPositiveError),
          findsOneWidget,
        );

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

        expect(find.text(l10n.equipmentDurationNotPositiveError), findsNothing);
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
        expect(
          find.text(l10n.equipmentDurationNotPositiveError),
          findsOneWidget,
        );

        await tester.enterText(find.byKey(const Key('duration_field')), '2');
        await tester.pump();
        await unfocusAll(tester);

        expect(find.text(l10n.equipmentDurationNotPositiveError), findsNothing);
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

    testWidgets(
      'calls onTotalChanged with 0 (not the raw product) when duration is '
      'not a half-day step',
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

        await tester.enterText(find.byKey(const Key('duration_field')), '1.3');
        await tester.pump();

        expect(capturedTotal, 0.0);
      },
    );

    testWidgets(
      'calls onTotalChanged with 0 (not a negative product) when the rate '
      'is out of range',
      (tester) async {
        double? capturedTotal;
        await tester.pumpWidget(
          makeWidget(onTotalChanged: (total) => capturedTotal = total),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('duration_field')), '3');
        await tester.pump();
        await tester.enterText(find.byKey(const Key('rate_field')), '-200');
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
      // The header shows the same raw digits as the field itself while
      // open (N12): it reads "Delivery 85", never "Delivery $85.00", so
      // the two never disagree mid-keystroke.
      expect(find.text('${l10n.equipmentDeliveryRowLabel} 85'), findsOneWidget);
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

  group('EquipmentCostFormFields — delivery fee never colors the field', () {
    // Per the storyboard: "Every digit is accepted. The app asks about a
    // large amount on Add to estimate, and never refuses a keypress or
    // colours the field." Range validity is enforced by the bloc (gates
    // Save/Submit, see equipment_cost_form_bloc_test.dart), not by a red
    // field error here.
    testWidgets(
      'an out-of-range delivery fee never shows a red field error, even '
      'once folded',
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
          tester
              .widget<UnderlineTextField>(
                find.byKey(const Key('delivery_fee_field')),
              )
              .errorTextList,
          isNull,
        );
      },
    );

    testWidgets(
      'a delivery fee of exactly 0 never shows a red field error, since '
      "it's a distinct, valid confirmed-free value",
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
          tester
              .widget<UnderlineTextField>(
                find.byKey(const Key('delivery_fee_field')),
              )
              .errorTextList,
          isNull,
        );
      },
    );
  });

  group('EquipmentCostFormFields — delivery fee has no status', () {
    testWidgets(
      'a typed fee shows no badge or Confirm link once folded, per the '
      'storyboard: a typed fee is final immediately',
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
          findsNothing,
        );
        expect(
          find.byKey(const Key('delivery_fee_confirm_link')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'a typed \$0.00 fee also shows no badge or link, per the storyboard: '
      'a confirmed-free fee has no tag',
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
          findsNothing,
        );
        expect(
          find.byKey(const Key('delivery_fee_confirm_link')),
          findsNothing,
        );
      },
    );

    testWidgets('shows no badge when unset', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('delivery_fee_estimated_badge')),
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
            DisplayFormatter.currency.format(580),
            l10n.equipmentDeliveryFeeOutsizedDialogDurationDays('4'),
            'excavator',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says "1 day", not "1 days", for a one-day duration', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'excavator',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('duration_field')), '1');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '145');
      await tester.pump();

      await expandDeliveryField(tester);
      await tester.enterText(
        find.byKey(const Key('delivery_fee_field')),
        '500',
      );
      await tester.pump();
      await foldDeliveryField(tester);
      await triggerOutsizedFeeCheck(tester);

      expect(
        find.text(
          l10n.equipmentDeliveryFeeOutsizedDialogBodyDay(
            DisplayFormatter.currency.format(500),
            DisplayFormatter.currency.format(145),
            l10n.equipmentDeliveryFeeOutsizedDialogOneDay,
            'excavator',
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
      // value stays put and editable. Focus is back on the field (see
      // below), so the row reads the raw digits too (N12), not formatted.
      expect(
        find.text('${l10n.equipmentDeliveryRowLabel} 8500'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, '8500'), findsOneWidget);
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
        expect(
          find.text('${l10n.equipmentDeliveryRowLabel} 8500'),
          findsOneWidget,
        );
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

        // A non-empty equipment name is required for "Save as my rate" to
        // offer itself (B5) — filled here so this test can also cover that
        // link, not just the badge.
        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Backhoe',
        );
        await tester.pump();
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
        // "Save as my rate" shows for any non-missing rate (CA-1151), not
        // just an unverified sample rate — including one already confirmed.
        // This link never sets an entryLabel, so per
        // YourRatesRepository.save's collision rule, re-saving is a
        // harmless idempotent overwrite only when the (companyId, category,
        // itemName) grouping is a single row with a null entryLabel; any
        // other existing row for the same equipment name instead triggers
        // the same label-collision dialog a first save into a populated
        // grouping would.
        expect(find.byKey(const Key('save_as_my_rate_link')), findsOneWidget);
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
        expect(find.text(l10n.equipmentRateStatusYourRateBadge), findsNothing);
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

  group('EquipmentCostFormFields — save as my rate', () {
    Future<YourRateEntry> seedRate({
      required String itemName,
      required double amount,
      required EquipmentPricingMethod method,
      String? entryLabel,
    }) async {
      final repository = Modular.get<YourRatesRepository>();
      // TODO: [CA-1180] seeded at '' to match the widget's current
      // _currentCompanyId stub, not a real company id — restore to a
      // non-empty value once the widget resolves a real one.
      await repository.save(
        YourRateEntry(
          id: '',
          companyId: '',
          itemName: itemName,
          category: CostItemType.equipment,
          rate: Money(amount: amount),
          savedAt: DateTime(2026, 1, 1),
          equipmentMethod: method,
          entryLabel: entryLabel,
        ),
      );
      final saved = await repository.search(
        itemName,
        category: CostItemType.equipment,
      );
      return saved.fold(
        (_) => throw StateError('seed search failed'),
        (entries) => entries.first,
      );
    }

    testWidgets('saving a new rate succeeds without a label prompt', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '150');
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('entry_label_dialog_title')), findsNothing);

      final repository = Modular.get<YourRatesRepository>();
      final saved = await repository.search(
        'Backhoe',
        category: CostItemType.equipment,
      );
      expect(saved.fold((_) => null, (e) => e.length), 1);
    });

    testWidgets(
      'saving a second rate for the same equipment prompts for a label',
      (tester) async {
        await seedRate(
          itemName: 'Backhoe',
          amount: 100,
          method: EquipmentPricingMethod.day,
          entryLabel: 'Supplier A',
        );
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Backhoe',
        );
        await tester.pump();
        await tester.enterText(find.byKey(const Key('rate_field')), '150');
        await tester.pump();

        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('entry_label_dialog_title')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('entry_label_dialog_save_button')),
        );
        await tester.pump();
        expect(
          find.text(l10n.yourRatesEntryLabelRequiredError),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('entry_label_field')),
          'Supplier B',
        );
        await tester.tap(
          find.byKey(const Key('entry_label_dialog_save_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('entry_label_dialog_title')), findsNothing);
        final repository = Modular.get<YourRatesRepository>();
        final saved = await repository.search(
          'Backhoe',
          category: CostItemType.equipment,
        );
        expect(saved.fold((_) => null, (e) => e.length), 2);
      },
    );

    testWidgets('shows a success toast after a successful save', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '150');
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.yourRatesSaveSucceededMessage), findsOneWidget);
    });

    testWidgets('shows an error toast when saving fails', (tester) async {
      fakeSupabase.shouldThrowOnInsert = true;
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Backhoe',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), '150');
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.yourRatesSaveFailedError), findsOneWidget);
      expect(
        find.text(l10n.yourRatesSaveSucceededMessage),
        findsNothing,
      );
    });

    testWidgets(
      'saving a Job-priced rate succeeds without a label prompt',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('job_method_chip')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Dumpster',
        );
        await tester.pump();
        await tester.enterText(find.byKey(const Key('amount_field')), '500');
        await tester.pump();

        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('entry_label_dialog_title')),
          findsNothing,
        );
        expect(find.text(l10n.yourRatesSaveSucceededMessage), findsOneWidget);

        final repository = Modular.get<YourRatesRepository>();
        final saved = await repository.search(
          'Dumpster',
          category: CostItemType.equipment,
        );
        expect(
          saved.fold((_) => null, (e) => e.single.equipmentMethod),
          EquipmentPricingMethod.job,
        );
      },
    );

    testWidgets(
      'Cancel dismisses the entry-label dialog without saving',
      (tester) async {
        await seedRate(
          itemName: 'Backhoe',
          amount: 100,
          method: EquipmentPricingMethod.day,
          entryLabel: 'Supplier A',
        );
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Backhoe',
        );
        await tester.pump();
        await tester.enterText(find.byKey(const Key('rate_field')), '150');
        await tester.pump();

        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('entry_label_dialog_title')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('entry_label_dialog_cancel_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('entry_label_dialog_title')),
          findsNothing,
        );
        // Neither a success nor an error toast fires for a cancelled retry —
        // the collision dialog's own dismissal is the only visible effect.
        expect(
          find.text(l10n.yourRatesSaveSucceededMessage),
          findsNothing,
        );
        expect(find.text(l10n.yourRatesSaveFailedError), findsNothing);

        final repository = Modular.get<YourRatesRepository>();
        final saved = await repository.search(
          'Backhoe',
          category: CostItemType.equipment,
        );
        // Still just the one seeded row — the cancelled retry never reached
        // the repository.
        expect(saved.fold((_) => null, (e) => e.length), 1);
      },
    );

    testWidgets(
      'a double tap on "Save as my rate" only produces one save '
      '(droppable transformer)',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Backhoe',
        );
        await tester.pump();
        await tester.enterText(find.byKey(const Key('rate_field')), '150');
        await tester.pump();

        fakeSupabase.completer = Completer();
        fakeSupabase.shouldDelayOperations = true;

        // Both taps fire before the first save's (delayed) repository call
        // resolves, so the second must be dropped by YourRatesBloc's
        // _droppable() transformer rather than queued or restarted.
        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pump();

        fakeSupabase.shouldDelayOperations = false;
        fakeSupabase.completer!.complete();
        await tester.pumpAndSettle();

        expect(fakeSupabase.getMethodCallsFor('insert').length, 1);
        expect(find.text(l10n.yourRatesSaveSucceededMessage), findsOneWidget);

        final repository = Modular.get<YourRatesRepository>();
        final saved = await repository.search(
          'Backhoe',
          category: CostItemType.equipment,
        );
        expect(saved.fold((_) => null, (e) => e.length), 1);
      },
    );

    testWidgets(
      'hides "Save as my rate" when the equipment name is empty',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('rate_field')), '150');
        await tester.pump();

        expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);
        expect(
          find.byKey(const Key('save_as_my_rate_helper_text')),
          findsNothing,
        );
      },
    );
  });
}
