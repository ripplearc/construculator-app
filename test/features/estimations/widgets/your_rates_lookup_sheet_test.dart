import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_lookup_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late AppLocalizations l10n;
  final clock = FakeClockImpl(DateTime(2026, 1, 15));

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    fakeSupabase.addTableData('your_rates', [
      for (var i = 0; i < 4; i++)
        {
          'id': 'rate-$i',
          'company_id': 'company-1',
          'category': 'equipment',
          'item_name': 'Excavator $i',
          'rate_amount': 100 + i,
          'rate_currency': 'USD',
          'equipment_method': 'day',
          'saved_at': DateTime(2026, 1, 15 - i).toIso8601String(),
        },
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
  });

  Future<void> openSheet(
    WidgetTester tester,
    List<YourRateEntry?> results, {
    EquipmentPricingMethod method = EquipmentPricingMethod.day,
    List<EquipmentPricingMethod>? switchedTo,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_sheet'),
                onPressed: () async {
                  results.add(
                    await YourRatesLookupSheet.show(
                      context: context,
                      method: method,
                      onSwitchMethod: (switched) => switchedTo?.add(switched),
                      clock: clock,
                      blocFactory: () => Modular.get<YourRatesBloc>(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  group('YourRatesLookupSheet – header', () {
    testWidgets('shows a back arrow next to the Look up a rate title', (
      tester,
    ) async {
      await openSheet(tester, []);

      expect(find.byKey(SheetHeader.backButtonKey), findsOneWidget);
      expect(find.text(l10n.yourRatesLookupTitle), findsOneWidget);
    });

    testWidgets('keeps the search field above the keyboard', (tester) async {
      fakeSupabase.reset();
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await openSheet(tester, []);

      final keyboardTop =
          (tester.view.physicalSize.height - 900) /
          tester.view.devicePixelRatio;
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(const Key('your_rates_search_field'))).bottom,
        lessThanOrEqualTo(keyboardTop),
      );
    });

    testWidgets('scrolls the results when the sheet is too short for them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 1200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await openSheet(tester, []);

      await tester.dragUntilVisible(
        find.byKey(const Key('your_rate_row_rate-3')),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('your_rate_row_rate-3')), findsOneWidget);
    });

    testWidgets('tapping the back arrow closes the sheet without a pick', (
      tester,
    ) async {
      final results = <YourRateEntry?>[];
      await openSheet(tester, results);

      await tester.tap(find.byKey(SheetHeader.backButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(YourRatesLookupSheet), findsNothing);
      expect(results, [null]);
    });
  });

  Map<String, dynamic> row(
    String id,
    String name, {
    String method = 'day',
    double amount = 100,
    DateTime? savedAt,
    DateTime? lastUsedAt,
  }) => {
    'id': id,
    'company_id': 'company-1',
    'category': 'equipment',
    'item_name': name,
    'rate_amount': amount,
    'rate_currency': 'USD',
    'equipment_method': method,
    'saved_at': (savedAt ?? DateTime(2026, 1, 1)).toIso8601String(),
    'last_used_at': lastUsedAt?.toIso8601String(),
  };

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byKey(CoreSearchBox.textFieldKey), query);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  group('YourRatesLookupSheet – rows', () {
    testWidgets('lists every saved rate of the active method, not four', (
      tester,
    ) async {
      fakeSupabase.reset();
      fakeSupabase.addTableData('your_rates', [
        for (var i = 0; i < 6; i++) row('day-$i', 'Excavator $i'),
        row('job-1', 'Dumpster', method: 'job'),
      ]);

      await openSheet(tester, []);

      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('your_rate_row_day-$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('your_rate_row_job-1')), findsNothing);
    });

    testWidgets(
      'a Job rate is listed when the newest rates are all Day rates',
      (tester) async {
        fakeSupabase.reset();
        fakeSupabase.addTableData('your_rates', [
          row(
            'job-1',
            'Dumpster',
            method: 'job',
            savedAt: DateTime(2025, 12, 1),
          ),
          for (var i = 0; i < 5; i++)
            row('day-$i', 'Excavator $i', savedAt: DateTime(2026, 1, 1 + i)),
        ]);

        await openSheet(tester, [], method: EquipmentPricingMethod.job);

        expect(find.byKey(const Key('your_rate_row_job-1')), findsOneWidget);
        expect(find.byKey(const Key('your_rates_empty_state')), findsNothing);
      },
    );

    testWidgets('dates each saved rate: Used when added to an estimate, Saved '
        'when never added', (tester) async {
      fakeSupabase.reset();
      fakeSupabase.addTableData('your_rates', [
        row(
          'used-rate',
          'Mini excavator',
          savedAt: DateTime(2025, 12, 1),
          lastUsedAt: DateTime(2026, 1, 8),
        ),
        row('saved-rate', 'Scissor lift', savedAt: DateTime(2026, 1, 12)),
      ]);

      await openSheet(tester, []);

      expect(
        find.descendant(
          of: find.byKey(const Key('your_rate_row_used-rate')),
          matching: find.text('Used last week'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('your_rate_row_saved-rate')),
          matching: find.text('Saved 3 days ago'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('lists a rate used after a newer save above that save', (
      tester,
    ) async {
      fakeSupabase.reset();
      fakeSupabase.addTableData('your_rates', [
        row('saved-later', 'Scissor lift', savedAt: DateTime(2026, 1, 10)),
        row(
          'used-later',
          'Mini excavator',
          savedAt: DateTime(2025, 12, 1),
          lastUsedAt: DateTime(2026, 1, 14),
        ),
      ]);

      await openSheet(tester, []);

      expect(
        tester.getTopLeft(find.byKey(const Key('your_rate_row_used-later'))).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const Key('your_rate_row_saved-later')))
              .dy,
        ),
      );
    });

    testWidgets('does not show the sample-rate notice', (tester) async {
      await openSheet(tester, []);

      expect(find.byKey(const Key('your_rates_disclaimer')), findsNothing);
    });
  });

  group('YourRatesLookupSheet – selecting a rate', () {
    testWidgets('shows the Use button for the selected row and returns it', (
      tester,
    ) async {
      final results = <YourRateEntry?>[];
      await openSheet(tester, results);

      await tester.tap(find.byKey(const Key('your_rate_row_rate-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('your_rates_use_button')));
      await tester.pumpAndSettle();

      expect(results.single?.id, 'rate-1');
    });

    testWidgets('a Job pick returns a Job entry with its amount', (
      tester,
    ) async {
      fakeSupabase.reset();
      fakeSupabase.addTableData('your_rates', [
        row('job-1', 'Dumpster', method: 'job', amount: 400),
      ]);
      final results = <YourRateEntry?>[];
      await openSheet(tester, results, method: EquipmentPricingMethod.job);

      await tester.tap(find.byKey(const Key('your_rate_row_job-1')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          l10n.yourRatesUseButtonLabel('\$400.00', l10n.yourRatesJobSuffix),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('your_rates_use_button')));
      await tester.pumpAndSettle();

      expect(results.single?.equipmentMethod, EquipmentPricingMethod.job);
      expect(results.single?.rate.amount, 400);
    });

    testWidgets('tapping the selected row again deselects it', (tester) async {
      await openSheet(tester, []);

      await tester.tap(find.byKey(const Key('your_rate_row_rate-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('your_rates_use_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('your_rate_row_rate-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('your_rates_use_button')), findsNothing);
    });

    testWidgets('hides the Use button when the selected row is not on screen', (
      tester,
    ) async {
      await openSheet(tester, []);
      await tester.tap(find.byKey(const Key('your_rate_row_rate-0')));
      await tester.pumpAndSettle();

      await search(tester, '3');

      expect(find.byKey(const Key('your_rate_row_rate-0')), findsNothing);
      expect(find.byKey(const Key('your_rate_row_rate-3')), findsOneWidget);
      expect(find.byKey(const Key('your_rates_use_button')), findsNothing);
    });

    testWidgets('a search with no match shows the line and no Use button', (
      tester,
    ) async {
      await openSheet(tester, []);
      await tester.tap(find.byKey(const Key('your_rate_row_rate-0')));
      await tester.pumpAndSettle();

      await search(tester, 'stump grinder');

      expect(
        find.text(l10n.yourRatesNoMatchState('stump grinder')),
        findsOneWidget,
      );
      expect(find.text('No matches for “stump grinder”'), findsOneWidget);
      expect(find.byKey(const Key('your_rates_use_button')), findsNothing);
    });

    testWidgets('the clear button has a clear label', (tester) async {
      await openSheet(tester, []);
      await search(tester, 'Excavator');

      expect(
        find.bySemanticsLabel(l10n.yourRatesClearSearchSemanticLabel),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(l10n.yourRatesLookupButton), findsNothing);
    });
  });

  group('YourRatesLookupSheet – when the saved prices cannot be read', () {
    testWidgets('shows the error row, never the no-saved-rates text', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnSelectMatch = true;

      await openSheet(tester, []);

      expect(find.byKey(const Key('your_rates_load_error')), findsOneWidget);
      expect(find.text(l10n.yourRatesLoadError), findsOneWidget);
      expect(
        find.byKey(const Key('your_rates_try_again_button')),
        findsOneWidget,
      );
      expect(find.text(l10n.yourRatesEmptyState), findsNothing);
      expect(find.byKey(const Key('your_rates_empty_state')), findsNothing);
    });

    testWidgets('Try again searches again and shows the rows when it works', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnSelectMatch = true;
      await openSheet(tester, []);

      fakeSupabase.shouldThrowOnSelectMatch = false;
      await tester.tap(find.byKey(const Key('your_rates_try_again_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('your_rates_load_error')), findsNothing);
      expect(find.byKey(const Key('your_rate_row_rate-0')), findsOneWidget);
    });

    testWidgets('a failed search keeps the typed words for Try again', (
      tester,
    ) async {
      await openSheet(tester, []);
      fakeSupabase.shouldThrowOnSelectMatch = true;
      await search(tester, '1');
      expect(find.byKey(const Key('your_rates_load_error')), findsOneWidget);

      fakeSupabase.shouldThrowOnSelectMatch = false;
      await tester.tap(find.byKey(const Key('your_rates_try_again_button')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('your_rate_row_rate-1')), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_rate-0')), findsNothing);
    });
  });

  group('YourRatesLookupSheet – a match under the other pricing method', () {
    const noticeKey = Key('your_rates_other_method_notice');
    const actionKey = Key('your_rates_other_method_action');

    void seed(List<Map<String, dynamic>> rows) {
      fakeSupabase.reset();
      fakeSupabase.addTableData('your_rates', rows);
    }

    testWidgets(
      'Day active, only a job price matches: says so in place of the plain '
      'no-match line, with the action to show job prices',
      (tester) async {
        seed([row('job-1', 'Dumpster', method: 'job', amount: 340)]);
        await openSheet(tester, []);

        await search(tester, 'dumpster');

        expect(
          find.text(
            'No day rates for “dumpster”. It has a job price of \$340.00.',
          ),
          findsOneWidget,
        );
        expect(find.text(l10n.yourRatesShowJobPrices), findsOneWidget);
        expect(find.byKey(noticeKey), findsOneWidget);
        expect(find.byKey(const Key('your_rates_empty_state')), findsNothing);
        expect(find.byKey(const Key('your_rate_row_job-1')), findsNothing);
      },
    );

    testWidgets('Job active, only a day rate matches: offers the day rates', (
      tester,
    ) async {
      seed([row('day-1', 'Dumpster', amount: 120)]);
      await openSheet(tester, [], method: EquipmentPricingMethod.job);

      await search(tester, 'dumpster');

      expect(
        find.text(
          'No job prices for “dumpster”. It has a day rate of \$120.00.',
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.yourRatesShowDayRates), findsOneWidget);
    });

    testWidgets('several matches give the count and the range', (tester) async {
      seed([
        row('job-1', 'Dumpster 10 yd', method: 'job', amount: 340),
        row('job-2', 'Dumpster 20 yd', method: 'job', amount: 520),
        row('job-3', 'Dumpster 30 yd', method: 'job', amount: 400),
      ]);
      await openSheet(tester, []);

      await search(tester, 'dumpster');

      expect(
        find.text(
          'No day rates for “dumpster”. It has 3 job prices, '
          'from \$340.00 to \$520.00.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping the action switches the caller to the other method '
        'and keeps the typed words', (tester) async {
      seed([row('job-1', 'Dumpster', method: 'job', amount: 340)]);
      final switched = <EquipmentPricingMethod>[];
      await openSheet(tester, [], switchedTo: switched);
      await search(tester, 'dumpster');

      await tester.tap(find.byKey(actionKey));
      await tester.pumpAndSettle();

      expect(switched, [EquipmentPricingMethod.job]);
      expect(find.byKey(noticeKey), findsNothing);
      expect(find.text('dumpster'), findsOneWidget);
    });

    testWidgets('after the switch a lone match is listed as a job price, '
        'selected, with the Use button naming it', (tester) async {
      seed([row('job-1', 'Dumpster', method: 'job', amount: 340)]);
      await openSheet(tester, []);
      await search(tester, 'dumpster');

      await tester.tap(find.byKey(actionKey));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('your_rate_row_job-1')), findsOneWidget);
      expect(
        find.widgetWithText(
          CoreButton,
          l10n.yourRatesUseButtonLabel('\$340.00', 'job'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('after the switch several matches are listed and none is '
        'selected until one is tapped', (tester) async {
      seed([
        row('job-1', 'Dumpster 10 yd', method: 'job', amount: 340),
        row('job-2', 'Dumpster 20 yd', method: 'job', amount: 520),
      ]);
      await openSheet(tester, []);
      await search(tester, 'dumpster');

      await tester.tap(find.byKey(actionKey));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('your_rate_row_job-1')), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_job-2')), findsOneWidget);
      expect(find.byKey(const Key('your_rates_use_button')), findsNothing);

      await tester.tap(find.byKey(const Key('your_rate_row_job-2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('your_rates_use_button')), findsOneWidget);
    });

    testWidgets('using the lone match after the switch returns that rate', (
      tester,
    ) async {
      seed([row('job-1', 'Dumpster', method: 'job', amount: 340)]);
      final results = <YourRateEntry?>[];
      await openSheet(tester, results);
      await search(tester, 'dumpster');
      await tester.tap(find.byKey(actionKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('your_rates_use_button')));
      await tester.pumpAndSettle();

      expect(results.single?.id, 'job-1');
      expect(results.single?.equipmentMethod, EquipmentPricingMethod.job);
    });

    testWidgets('a match under neither method keeps the plain no-match line', (
      tester,
    ) async {
      seed([row('job-1', 'Dumpster', method: 'job')]);
      await openSheet(tester, []);

      await search(tester, 'crane');

      expect(find.text(l10n.yourRatesNoMatchState('crane')), findsOneWidget);
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets(
      'a match under the active method lists it and shows no notice',
      (tester) async {
        seed([
          row('day-1', 'Dumpster', amount: 120),
          row('job-1', 'Dumpster XL', method: 'job', amount: 340),
        ]);
        await openSheet(tester, []);

        await search(tester, 'dumpster');

        expect(find.byKey(const Key('your_rate_row_day-1')), findsOneWidget);
        expect(find.byKey(noticeKey), findsNothing);
      },
    );

    testWidgets('no search typed: the empty list stays plain even when the '
        'other method has rates', (tester) async {
      seed([row('job-1', 'Dumpster', method: 'job')]);

      await openSheet(tester, []);

      expect(find.byKey(const Key('your_rates_empty_state')), findsOneWidget);
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('a failed read shows the error row, not the notice', (
      tester,
    ) async {
      seed([row('job-1', 'Dumpster', method: 'job')]);
      await openSheet(tester, []);
      fakeSupabase.shouldThrowOnSelectMatch = true;

      await search(tester, 'dumpster');

      expect(find.byKey(const Key('your_rates_load_error')), findsOneWidget);
      expect(find.byKey(noticeKey), findsNothing);
    });
  });
}
