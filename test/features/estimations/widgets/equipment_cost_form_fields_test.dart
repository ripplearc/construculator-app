import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/equipment_cost_form_fields.dart';
import 'package:construculator/features/estimation/presentation/widgets/underline_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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
          ),
        ),
      ),
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

    testWidgets('shows placeholder text on the empty name, duration, and '
        'rate fields', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.equipmentNamePlaceholder), findsOneWidget);
      expect(find.text(l10n.equipmentDurationPlaceholder), findsOneWidget);
      expect(find.text(l10n.equipmentRatePlaceholder), findsOneWidget);
    });

    testWidgets('shows placeholder text on the empty amount field (Job)', (
      tester,
    ) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.equipmentAmountPlaceholder), findsOneWidget);
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

      final empty = tester.getTopLeft(find.text('days')).dx;
      final one = await daysLeftAfterTyping(tester, '4');
      final many = await daysLeftAfterTyping(tester, '4444444');
      final backToOne = await daysLeftAfterTyping(tester, '4');

      expect(one, lessThan(empty));
      expect(many, greaterThan(one));
      expect(backToOne, one);
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
            .widget<CoreChip>(find.byKey(const Key('job_method_chip')))
            .selected
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CoreChip>(find.byKey(const Key('day_method_chip')))
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
        tester.widget<CoreChip>(find.byKey(const Key('day_method_chip'))),
        isA<CoreChip>().having((c) => c.selected.value, 'selected', true),
      );
      expect(
        tester.widget<CoreChip>(find.byKey(const Key('job_method_chip'))),
        isA<CoreChip>().having((c) => c.selected.value, 'selected', false),
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
        tester.widget<CoreChip>(find.byKey(const Key('job_method_chip'))),
        isA<CoreChip>().having((c) => c.selected.value, 'selected', true),
      );
      expect(
        tester.widget<CoreChip>(find.byKey(const Key('day_method_chip'))),
        isA<CoreChip>().having((c) => c.selected.value, 'selected', false),
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
    testWidgets(
      'shows the too-large error once the field loses focus above the limit',
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
}
