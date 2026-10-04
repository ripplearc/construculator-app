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
    YourRateEntry? initialRateEntry,
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
            initialRateEntry: initialRateEntry,
          ),
        ),
      ),
    );
  }

  Future<void> unfocusAll(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
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

  // Stands in for tapping "Add to estimate", which is still a no-op stub
  // outside this widget (CA-355): the bloc decides whether the submit needs
  // the outsized-fee dialog.
  Future<void> triggerOutsizedFeeCheck(WidgetTester tester) async {
    final nameField = find.byKey(const Key('equipment_name_field'));
    if (tester.widget<UnderlineTextField>(nameField).controller.text.isEmpty) {
      await tester.enterText(nameField, 'Excavator');
      await tester.pump();
    }
    BlocProvider.of<EquipmentCostFormBloc>(
      tester.element(find.byType(EquipmentCostFormFields)),
    ).add(const EquipmentCostSubmittedEvent(estimateId: 'estimate-1'));
    await tester.pumpAndSettle();
  }

  String deliveryRowText([double? fee]) {
    final value = fee == null
        ? l10n.equipmentDeliveryFeeUnsetText
        : DisplayFormatter.currency.format(fee);
    return '${l10n.equipmentDeliveryRowLabel} $value';
  }

  // Matches the compact header's Subtitle text (e.g. "$145.00 /day · your
  // default") shown once a rate is recalled from Your Rates (CA-1146,
  // Figma nodes 66337:158600/66337:159434).
  String recalledRateSubtitleText(double amount, EquipmentPricingMethod method) {
    final unit = method == EquipmentPricingMethod.day
        ? l10n.yourRatesDaySuffix
        : l10n.yourRatesJobSuffix;
    return l10n.equipmentRecalledRateSubtitle(
      DisplayFormatter.currency.format(amount),
      unit,
    );
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

    testWidgets('shows placeholder text on the empty name, duration and '
        'rate fields', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.equipmentNamePlaceholder), findsOneWidget);
      expect(find.text(l10n.equipmentDurationPlaceholder), findsOneWidget);
      expect(find.text(l10n.equipmentRatePlaceholder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows placeholder text on the empty amount field (Job)', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.equipmentAmountPlaceholder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the rate placeholder again after the typed rate, its '
        'status badge and its trailing link are cleared', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('rate_field')), '145');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byKey(const Key('rate_field')), '');
      await tester.pumpAndSettle();
      expect(find.text(l10n.equipmentRatePlaceholder), findsOneWidget);
      expect(tester.takeException(), isNull);
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

  group('EquipmentCostFormFields — days suffix position', () {
    Future<double> daysLeftAfterTyping(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(const Key('duration_field')), text);
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.text('days')).dx;
    }

    testWidgets('days follows the typed number to the right and back to the '
        'left', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      final one = await daysLeftAfterTyping(tester, '4');
      final many = await daysLeftAfterTyping(tester, '4444444');
      final backToOne = await daysLeftAfterTyping(tester, '4');

      expect(many, greaterThan(one));
      expect(backToOne, one);
    });

    testWidgets('days is hidden while the duration field is empty', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.text('days'), findsNothing);

      await tester.enterText(find.byKey(const Key('duration_field')), '4');
      await tester.pumpAndSettle();
      expect(find.text('days'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('duration_field')), '');
      await tester.pumpAndSettle();
      expect(find.text('days'), findsNothing);
    });

    testWidgets('tapping the empty duration row still focuses the field', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      final field = tester.getRect(find.byKey(const Key('duration_field')));
      await tester.tapAt(Offset(field.right - 8, field.center.dy - 2));
      await tester.pumpAndSettle();

      final focused = tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('duration_field')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus;
      expect(focused, isTrue);
    });

    testWidgets('a very long duration keeps days inside the row without '
        'overflowing', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await daysLeftAfterTyping(tester, '1234567890' * 3);

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopRight(find.text('days')).dx,
        lessThanOrEqualTo(tester.view.physicalSize.width),
      );
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

    testWidgets('chips follow a method change that does not come from a tap', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      final bloc = BlocProvider.of<EquipmentCostFormBloc>(
        tester.element(find.byType(EquipmentCostFormFields)),
      );

      bloc.add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job));
      await tester.pump();

      expect(
        tester
            .widget<ChoiceChipToggle>(find.byKey(const Key('job_method_chip')))
            .selected
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChipToggle>(find.byKey(const Key('day_method_chip')))
            .selected
            .value,
        isFalse,
      );
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

  group('EquipmentCostFormFields — no errors on untouched fields', () {
    testWidgets('tapping Job on a fresh form shows no error text', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pumpAndSettle();

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
    testWidgets('shows no duration error while the user is still typing', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '0');
      await tester.pump();

      expect(find.text(l10n.equipmentDurationNotPositiveError), findsNothing);
    });

    testWidgets('shows the duration error when the field loses focus with 0', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '0');
      await tester.pump();
      await unfocusAll(tester);

      expect(find.text(l10n.equipmentDurationNotPositiveError), findsOneWidget);
    });

    testWidgets(
      'shows the half-day error when the field loses focus with 1.3',
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
      'shows the too-large error when the field loses focus above the limit',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('duration_field')),
          '100000000',
        );
        await tester.pump();
        await unfocusAll(tester);

        expect(find.text(l10n.equipmentDurationTooLargeError), findsOneWidget);
      },
    );

    testWidgets('turns the Duration label red once the error shows', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      final colors = AppColorsExtension.of(
        tester.element(find.byKey(const Key('duration_field'))),
      );
      Color? labelColor() => tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('duration_field')),
              matching: find.text(l10n.equipmentDurationLabel),
            ),
          )
          .style
          ?.color;

      expect(labelColor(), colors.textBody);

      await tester.enterText(find.byKey(const Key('duration_field')), '0');
      await tester.pump();
      expect(labelColor(), colors.textBody);

      await unfocusAll(tester);

      expect(labelColor(), colors.statusError);
    });

    testWidgets(
      'after the first blur the error follows every key and goes away as soon '
      'as the value is valid',
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

        await tester.enterText(find.byKey(const Key('duration_field')), '1.3');
        await tester.pump();
        expect(
          find.text(l10n.equipmentDurationNotHalfDayError),
          findsOneWidget,
        );

        await tester.enterText(find.byKey(const Key('duration_field')), '2');
        await tester.pump();
        expect(find.text(l10n.equipmentDurationNotHalfDayError), findsNothing);
        expect(find.text(l10n.equipmentDurationNotPositiveError), findsNothing);
      },
    );

    testWidgets('never shows an error for an empty field', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('duration_field')), '0');
      await tester.pump();
      await unfocusAll(tester);
      await tester.enterText(find.byKey(const Key('duration_field')), '');
      await tester.pump();

      expect(find.text(l10n.equipmentDurationNotPositiveError), findsNothing);
    });

    testWidgets(
      'shows the rate out-of-range error when the field loses focus above the bound',
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
      'shows the amount out-of-range error when the field loses focus above the bound',
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

    testWidgets('clears the amount error as soon as a valid amount is typed', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('amount_field')), '1000000');
      await tester.pump();
      await unfocusAll(tester);
      expect(find.text(l10n.equipmentAmountOutOfRangeError), findsOneWidget);

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
      expect(
        find.text('${l10n.equipmentDeliveryRowLabel} \$85'),
        findsOneWidget,
      );
      expect(
        find.text('${l10n.equipmentDeliveryRowLabel} \$85.00'),
        findsNothing,
      );
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

    testWidgets('says "one day", not "one days", for a one-day duration', (
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
      expect(
        find.text('${l10n.equipmentDeliveryRowLabel} \$8500'),
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

    testWidgets('"Go back" opens a folded Delivery panel and selects the fee', (
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
      await tester.tap(find.byKey(const Key('delivery_fee_row')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('delivery_fee_field')), findsNothing);
      await triggerOutsizedFeeCheck(tester);

      await tester.tap(
        find.byKey(const Key('outsized_fee_dialog_go_back_button')),
      );
      await tester.pumpAndSettle();

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
          find.text('${l10n.equipmentDeliveryRowLabel} \$8500'),
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

    testWidgets('a delivery fee above the accepted bound is left out of the '
        'total', (tester) async {
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
      await tester.enterText(
        find.byKey(const Key('delivery_fee_field')),
        '5000000',
      );
      await tester.pump();

      expect(capturedTotal, 400.0);
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

        expect(find.byKey(const Key('rate_status_badge')), findsNothing);
        expect(find.text(l10n.equipmentRateStatusYourRateBadge), findsNothing);
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

    testWidgets(
      'picking a Your-rates entry keeps the full form: name field, Day and '
      'Job buttons, no saved-rate title, no tag and no link',
      (tester) async {
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

        expect(find.byKey(const Key('equipment_name_field')), findsOneWidget);
        expect(find.byKey(const Key('day_method_chip')), findsOneWidget);
        expect(find.byKey(const Key('job_method_chip')), findsOneWidget);
        expect(find.byKey(const Key('recalled_rate_title')), findsNothing);
        expect(find.text(l10n.equipmentRateStatusYourRateBadge), findsNothing);
        expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);
        expect(find.text('145'), findsOneWidget);
      },
    );

    testWidgets('picking a Your-rates entry keeps the name already typed', (
      tester,
    ) async {
      await seedRate(
        itemName: 'Mini excavator — 1.5 ton',
        amount: 145,
        method: EquipmentPricingMethod.day,
      );
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'mini excavator 1.5t',
      );

      await tester.tap(find.byKey(const Key('lookup_rate_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mini excavator — 1.5 ton'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('your_rates_use_button')));
      await tester.pumpAndSettle();

      expect(find.text('mini excavator 1.5t'), findsOneWidget);
      expect(find.text('Mini excavator — 1.5 ton'), findsNothing);
      expect(find.text('145'), findsOneWidget);
    });

    testWidgets(
      'a picked rate stays editable with no tag, and clearing it brings the '
      'look-up button back',
      (tester) async {
        await seedRate(
          itemName: 'Scissor lift',
          amount: 145,
          method: EquipmentPricingMethod.day,
        );
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('lookup_rate_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Scissor lift'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('your_rates_use_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('rate_status_badge')), findsNothing);
        expect(find.byKey(const Key('lookup_rate_button')), findsNothing);

        await tester.enterText(find.byKey(const Key('rate_field')), '999');
        await tester.pump();
        expect(find.text('999'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('rate_field')), '');
        await tester.pump();
        expect(find.byKey(const Key('lookup_rate_button')), findsOneWidget);
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

  // CA-1146: CUJ 6 Sub-flows B (saved day rate) and C (saved job price).
  // Figma's actual B2/C2 confirmation screens (nodes 66337:158600 and
  // 66337:159434) replace the full entry form with a compact Title/Subtitle
  // header plus a single editable field — not the full form with a
  // read-only Rate field.
  //
  // Sub-flow D (switching pricing methods) stays covered by the generic
  // 'Day/Job toggle' group above: that toggle only ever appears on an
  // unsaved draft (RateStatus other than ownRateConfirmed) — Figma's B2/C2
  // have no toggle at all, so once a rate is recalled there is no UI path
  // left to switch methods on that line. That absence is asserted directly
  // below ("hides the equipment-name field, Day/Job toggle, ...").
  group('EquipmentCostFormFields — recalled rate (Sub-flows B, C)', () {
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

    Future<void> recallRate(
      WidgetTester tester,
      String itemName, {
      ValueChanged<double>? onTotalChanged,
      ValueChanged<bool>? onSaveEnabledChanged,
    }) async {
      final repository = Modular.get<YourRatesRepository>();
      final entries = (await repository.search(
        itemName,
        category: CostItemType.equipment,
      )).fold((_) => throw StateError('search failed'), (found) => found);
      final entry = entries.firstWhere((e) => e.itemName == itemName);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        makeWidget(
          initialRateEntry: entry,
          onTotalChanged: onTotalChanged,
          onSaveEnabledChanged: onSaveEnabledChanged,
        ),
      );
      await tester.pumpAndSettle();
    }

    // Widgets that only ever belong to the full, not-yet-recalled form —
    // none of these appear in Figma's B2/C2 confirmation header.
    void expectFullFormChromeAbsent(WidgetTester tester) {
      expect(find.byKey(const Key('equipment_name_field')), findsNothing);
      expect(find.byKey(const Key('day_method_chip')), findsNothing);
      expect(find.byKey(const Key('job_method_chip')), findsNothing);
      expect(find.byKey(const Key('rate_status_badge')), findsNothing);
      expect(find.byKey(const Key('lookup_rate_button')), findsNothing);
    }

    group('Sub-flow B: saved day rate', () {
      testWidgets(
        'shows the equipment name as a Title and the saved rate as a '
        'Subtitle, with Duration as the only field',
        (tester) async {
          await seedRate(
            itemName: 'Scissor lift',
            amount: 145,
            method: EquipmentPricingMethod.day,
          );
          await tester.pumpWidget(makeWidget());
          await tester.pumpAndSettle();

          await recallRate(tester, 'Scissor lift');

          expect(find.text('Scissor lift'), findsOneWidget);
          expect(
            find.text(
              recalledRateSubtitleText(145, EquipmentPricingMethod.day),
            ),
            findsOneWidget,
          );
          expect(find.byKey(const Key('rate_field')), findsNothing);
          expect(find.byKey(const Key('duration_field')), findsOneWidget);
        },
      );

      testWidgets(
        'hides the equipment-name field, Day/Job toggle, rate-status badge, '
        'and save-as-my-rate link/magnifier',
        (tester) async {
          await seedRate(
            itemName: 'Scissor lift',
            amount: 145,
            method: EquipmentPricingMethod.day,
          );
          await tester.pumpWidget(makeWidget());
          await tester.pumpAndSettle();

          await recallRate(tester, 'Scissor lift');
          expect(find.byKey(const Key('lookup_rate_button')), findsNothing);

          expectFullFormChromeAbsent(tester);
        },
      );

      testWidgets(
        'delivery is still offered and stays unpriced after recalling a day '
        'rate',
        (tester) async {
          await seedRate(
            itemName: 'Scissor lift',
            amount: 145,
            method: EquipmentPricingMethod.day,
          );
          await tester.pumpWidget(makeWidget());
          await tester.pumpAndSettle();

          await recallRate(tester, 'Scissor lift');

          expect(find.byKey(const Key('delivery_fee_row')), findsOneWidget);
          expect(find.text(deliveryRowText()), findsOneWidget);
        },
      );

      testWidgets(
        'Add to estimate stays disabled until Duration is entered',
        (tester) async {
          await seedRate(
            itemName: 'Scissor lift',
            amount: 145,
            method: EquipmentPricingMethod.day,
          );
          var saveEnabled = true;
          await recallRate(
            tester,
            'Scissor lift',
            onSaveEnabledChanged: (enabled) => saveEnabled = enabled,
          );
          expect(saveEnabled, isFalse);

          await tester.enterText(find.byKey(const Key('duration_field')), '3');
          await tester.pump();
          expect(saveEnabled, isTrue);
        },
      );

      testWidgets(
        'the total is duration × the recalled rate, same as the full form',
        (tester) async {
          await seedRate(
            itemName: 'Scissor lift',
            amount: 145,
            method: EquipmentPricingMethod.day,
          );
          double? total;
          await recallRate(
            tester,
            'Scissor lift',
            onTotalChanged: (value) => total = value,
          );
          await tester.enterText(find.byKey(const Key('duration_field')), '3');
          await tester.pump();

          expect(total, 435.0);
        },
      );
    });

    group('Sub-flow B: fractional saved rate', () {
      testWidgets(
        'a fractional saved rate renders as a two-decimal currency amount in '
        'the subtitle',
        (tester) async {
          await seedRate(
            itemName: 'Skid steer',
            amount: 132.5,
            method: EquipmentPricingMethod.day,
          );

          await recallRate(tester, 'Skid steer');

          expect(
            find.text(
              recalledRateSubtitleText(132.5, EquipmentPricingMethod.day),
            ),
            findsOneWidget,
          );
        },
      );
    });

    group('Sub-flow C: saved job price', () {
      testWidgets(
        'typing a new amount keeps the compact screen: still no name field '
        'and no Day or Job buttons',
        (tester) async {
          await seedRate(
            itemName: 'Dumpster',
            amount: 400,
            method: EquipmentPricingMethod.job,
          );
          await recallRate(tester, 'Dumpster');
          expectFullFormChromeAbsent(tester);

          await tester.enterText(find.byKey(const Key('amount_field')), '450');
          await tester.pumpAndSettle();

          expectFullFormChromeAbsent(tester);
          expect(find.byKey(const Key('recalled_rate_title')), findsOneWidget);
          expect(find.text('Dumpster'), findsOneWidget);
        },
      );

      testWidgets(
        'tapping the amount field does not bring the full form back',
        (tester) async {
          await seedRate(
            itemName: 'Dumpster',
            amount: 400,
            method: EquipmentPricingMethod.job,
          );
          await recallRate(tester, 'Dumpster');

          await tester.tap(find.byKey(const Key('amount_field')));
          await tester.pumpAndSettle();

          expectFullFormChromeAbsent(tester);
        },
      );

      testWidgets(
        'shows the equipment name as a Title, the saved price as a '
        'Subtitle, and Amount pre-filled and editable',
        (tester) async {
          await seedRate(
            itemName: 'Dumpster',
            amount: 400,
            method: EquipmentPricingMethod.job,
          );
          var saveEnabled = false;
          await recallRate(
            tester,
            'Dumpster',
            onSaveEnabledChanged: (enabled) => saveEnabled = enabled,
          );

          expect(find.text('Dumpster'), findsOneWidget);
          expect(
            find.text(
              recalledRateSubtitleText(400, EquipmentPricingMethod.job),
            ),
            findsOneWidget,
          );
          // A confirmation, not a form: nothing else to fill in before Add
          // is available.
          expect(saveEnabled, isTrue);

          await tester.enterText(find.byKey(const Key('amount_field')), '450');
          await tester.pump();
          expect(find.text('450'), findsOneWidget);
        },
      );

      testWidgets(
        'hides the equipment-name field, Day/Job toggle, rate-status badge, '
        'and save-as-my-rate link/magnifier',
        (tester) async {
          await seedRate(
            itemName: 'Dumpster',
            amount: 400,
            method: EquipmentPricingMethod.job,
          );
          await tester.pumpWidget(makeWidget());
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('job_method_chip')));
          await tester.pump();

        await recallRate(tester, 'Dumpster');

          expectFullFormChromeAbsent(tester);
        },
      );

      testWidgets(
        'the line total is the job amount alone — no quantity or per-unit '
        'rate multiplier',
        (tester) async {
          await seedRate(
            itemName: 'Dumpster',
            amount: 400,
            method: EquipmentPricingMethod.job,
          );
          double? total;
          await recallRate(
            tester,
            'Dumpster',
            onTotalChanged: (value) => total = value,
          );

          expect(total, 400.0);
        },
      );
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
      await repository.save(
        YourRateEntry(
          id: '',
          companyId: 'company-1',
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

    Future<void> typeSavableRate(
      WidgetTester tester, {
      String name = 'Backhoe',
      String rate = '150',
    }) async {
      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        name,
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('rate_field')), rate);
      await tester.pump();
    }

    String hintText(WidgetTester tester) {
      final hint = find.descendant(
        of: find.byKey(const Key('save_as_my_rate_helper_text')),
        matching: find.byType(Text),
      );
      return tester.widget<Text>(hint).textSpan!.toPlainText();
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
      expect(saved.fold((_) => null, (e) => e.single.rate.amount), 150);
      expect(
        saved.fold((_) => null, (e) => e.single.equipmentMethod),
        EquipmentPricingMethod.day,
      );
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

    testWidgets(
      'a name typed with other capitals and extra spaces still asks for a '
      'label and keeps the saved price',
      (tester) async {
        await seedRate(
          itemName: 'Mini excavator',
          amount: 145,
          method: EquipmentPricingMethod.day,
        );
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await typeSavableRate(tester, name: '  mini   EXCAVATOR ', rate: '160');

        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('entry_label_dialog_title')),
          findsOneWidget,
        );
        final saved = await Modular.get<YourRatesRepository>().search(
          'Mini excavator',
          category: CostItemType.equipment,
        );
        expect(saved.fold((_) => null, (e) => e.single.rate.amount), 145);
      },
    );

    testWidgets(
      'a name with an unlabeled and a labeled price asks for a label and '
      'keeps both prices',
      (tester) async {
        await seedRate(
          itemName: 'Backhoe',
          amount: 100,
          method: EquipmentPricingMethod.day,
        );
        await seedRate(
          itemName: 'Backhoe',
          amount: 120,
          method: EquipmentPricingMethod.day,
          entryLabel: 'Supplier A',
        );
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await typeSavableRate(tester);

        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('entry_label_dialog_title')),
          findsOneWidget,
        );
        final saved = await Modular.get<YourRatesRepository>().search(
          'Backhoe',
          category: CostItemType.equipment,
        );
        expect(
          saved.fold(
            (_) => null,
            (e) => e.map((entry) => entry.rate.amount).toSet(),
          ),
          {100, 120},
        );
      },
    );

    testWidgets(
      'a label the name already uses keeps the dialog open with a line and '
      'replaces nothing',
      (tester) async {
        await seedRate(
          itemName: 'Backhoe',
          amount: 100,
          method: EquipmentPricingMethod.day,
          entryLabel: 'Supplier A',
        );
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await typeSavableRate(tester);
        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('entry_label_field')),
          'supplier   a',
        );
        await tester.tap(
          find.byKey(const Key('entry_label_dialog_save_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('entry_label_dialog_title')),
          findsOneWidget,
        );
        expect(find.text(l10n.yourRatesEntryLabelTakenError), findsOneWidget);
        final repository = Modular.get<YourRatesRepository>();
        final unchanged = await repository.search(
          'Backhoe',
          category: CostItemType.equipment,
        );
        expect(unchanged.fold((_) => null, (e) => e.single.rate.amount), 100);

        await tester.enterText(
          find.byKey(const Key('entry_label_field')),
          'Supplier B',
        );
        await tester.tap(
          find.byKey(const Key('entry_label_dialog_save_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('entry_label_dialog_title')), findsNothing);
        final both = await repository.search(
          'Backhoe',
          category: CostItemType.equipment,
        );
        expect(
          both.fold(
            (_) => null,
            (e) => e.map((entry) => entry.rate.amount).toSet(),
          ),
          {100, 150},
        );
      },
    );

    testWidgets(
      'after a successful save the link is gone and the hint says it is saved',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await typeSavableRate(tester);

        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);
        expect(
          hintText(tester),
          l10n.equipmentSavedToYourRatesHint(
            l10n.yourRatesName,
            'a',
            'backhoe',
          ),
        );
        expect(find.byKey(const Key('save_as_my_rate_error')), findsNothing);
      },
    );

    testWidgets(
      'when saving fails the error line shows under the Rate row and the '
      'link stays',
      (tester) async {
        fakeSupabase.shouldThrowOnInsert = true;
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await typeSavableRate(tester);

        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        expect(find.text(l10n.yourRatesSaveFailedError), findsOneWidget);
        expect(find.byKey(const Key('save_as_my_rate_link')), findsOneWidget);
        expect(
          find.byKey(const Key('save_as_my_rate_helper_text')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping the link again removes the error line while it runs and shows '
      'the saved hint when it works',
      (tester) async {
        fakeSupabase.shouldThrowOnInsert = true;
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await typeSavableRate(tester);
        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('save_as_my_rate_error')), findsOneWidget);

        fakeSupabase.shouldThrowOnInsert = false;
        fakeSupabase.completer = Completer();
        fakeSupabase.shouldDelayOperations = true;
        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pump();
        expect(find.byKey(const Key('save_as_my_rate_error')), findsNothing);

        fakeSupabase.shouldDelayOperations = false;
        fakeSupabase.completer!.complete();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);
        expect(hintText(tester), startsWith('Saved to ${l10n.yourRatesName}'));
      },
    );

    testWidgets(
      'changing the rate after a save brings the link back, and a second '
      'save asks for a label and keeps the saved price',
      (tester) async {
        await tester.pumpWidget(makeWidget());
        await tester.pumpAndSettle();
        await typeSavableRate(tester);
        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);

        await tester.enterText(find.byKey(const Key('rate_field')), '160');
        await tester.pump();
        expect(find.byKey(const Key('save_as_my_rate_link')), findsOneWidget);

        await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('entry_label_dialog_title')),
          findsOneWidget,
        );
        final repository = Modular.get<YourRatesRepository>();
        final beforeLabel = await repository.search(
          'Backhoe',
          category: CostItemType.equipment,
        );
        expect(beforeLabel.fold((_) => null, (e) => e.single.rate.amount), 150);

        await tester.enterText(
          find.byKey(const Key('entry_label_field')),
          'Supplier B',
        );
        await tester.tap(
          find.byKey(const Key('entry_label_dialog_save_button')),
        );
        await tester.pumpAndSettle();

        final afterLabel = await repository.search(
          'Backhoe',
          category: CostItemType.equipment,
        );
        expect(
          afterLabel.fold(
            (_) => null,
            (e) => e.map((entry) => entry.rate.amount).toSet(),
          ),
          {150, 160},
        );
      },
    );

    testWidgets('the hint before a save names the rate and the equipment', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await typeSavableRate(tester, name: 'Excavator');

      expect(
        hintText(tester),
        l10n.equipmentSaveAsMyRateHelperText(
          '\$150.00',
          l10n.yourRatesDaySuffix,
          l10n.yourRatesName,
          'an',
          'excavator',
        ),
      );
    });

    testWidgets('a Day rate of 0 offers no save link or hint', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await typeSavableRate(tester, rate: '0');

      expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);
      expect(
        find.byKey(const Key('save_as_my_rate_helper_text')),
        findsNothing,
      );
    });

    testWidgets('a Job amount of 0 offers no save link or hint', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Dumpster',
      );
      await tester.pump();

      await tester.enterText(find.byKey(const Key('amount_field')), '0');
      await tester.pump();

      expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);
      expect(
        find.byKey(const Key('save_as_my_rate_helper_text')),
        findsNothing,
      );
    });

    testWidgets('saves the equipment name without the spaces around it', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await typeSavableRate(tester, name: '  backhoe ');

      await tester.tap(find.byKey(const Key('save_as_my_rate_link')));
      await tester.pumpAndSettle();

      final saved = await Modular.get<YourRatesRepository>().search(
        'backhoe',
        category: CostItemType.equipment,
      );
      expect(saved.fold((_) => null, (e) => e.single.itemName), 'backhoe');
    });

    testWidgets('saving a Job-priced rate succeeds without a label prompt', (
      tester,
    ) async {
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

      expect(find.byKey(const Key('entry_label_dialog_title')), findsNothing);
      expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);

      final repository = Modular.get<YourRatesRepository>();
      final saved = await repository.search(
        'Dumpster',
        category: CostItemType.equipment,
      );
      expect(
        saved.fold((_) => null, (e) => e.single.equipmentMethod),
        EquipmentPricingMethod.job,
      );
      expect(saved.fold((_) => null, (e) => e.single.rate.amount), 500);
    });

    testWidgets('Cancel dismisses the entry-label dialog without saving', (
      tester,
    ) async {
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

      expect(find.byKey(const Key('entry_label_dialog_title')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('entry_label_dialog_cancel_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('entry_label_dialog_title')), findsNothing);
      expect(find.byKey(const Key('save_as_my_rate_error')), findsNothing);
      expect(find.byKey(const Key('save_as_my_rate_link')), findsOneWidget);

      final repository = Modular.get<YourRatesRepository>();
      final saved = await repository.search(
        'Backhoe',
        category: CostItemType.equipment,
      );
      // Still just the one seeded row — the cancelled retry never reached
      // the repository.
      expect(saved.fold((_) => null, (e) => e.length), 1);
    });

    testWidgets('a double tap on "Save as my rate" only produces one save '
        '(droppable transformer)', (tester) async {
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
      expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);

      final repository = Modular.get<YourRatesRepository>();
      final saved = await repository.search(
        'Backhoe',
        category: CostItemType.equipment,
      );
      expect(saved.fold((_) => null, (e) => e.length), 1);
    });

    testWidgets('hides "Save as my rate" when the equipment name is empty', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('rate_field')), '150');
      await tester.pump();

      expect(find.byKey(const Key('save_as_my_rate_link')), findsNothing);
      expect(
        find.byKey(const Key('save_as_my_rate_helper_text')),
        findsNothing,
      );
    });
  });
}
