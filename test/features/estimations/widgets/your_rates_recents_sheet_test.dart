import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_recents_sheet.dart';
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
  late FakeClockImpl clock;
  YourRatesRecentsResult? result;

  setUpAll(() {
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    result = null;
    fakeSupabase.addTableData('your_rates', [
      {
        'id': 'day-rate',
        'company_id': 'company-1',
        'category': 'equipment',
        'item_name': 'Scissor lift',
        'rate_amount': 120,
        'rate_currency': 'USD',
        'equipment_method': 'day',
        'saved_at': clock
            .now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
      },
      {
        'id': 'job-rate',
        'company_id': 'company-1',
        'category': 'equipment',
        'item_name': 'Scissor lift',
        'rate_amount': 400,
        'rate_currency': 'USD',
        'equipment_method': 'job',
        'saved_at': clock
            .now()
            .subtract(const Duration(days: 12))
            .toIso8601String(),
      },
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
  });

  Future<void> openSheet(WidgetTester tester) async {
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
                  result = await YourRatesRecentsSheet.show(
                    context: context,
                    clock: clock,
                    blocFactory: () => Modular.get<YourRatesBloc>(),
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

  group('YourRatesRecentsSheet – result', () {
    testWidgets('tapping a row returns picked with that exact entry', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('your_rate_row_job-rate')));
      await tester.pumpAndSettle();

      final picked = result;
      expect(picked, isA<YourRatesRecentsPicked>());
      expect((picked! as YourRatesRecentsPicked).entry.id, 'job-rate');
    });

    testWidgets('two rows with the same name return their own entries', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('your_rate_row_day-rate')));
      await tester.pumpAndSettle();

      expect((result! as YourRatesRecentsPicked).entry.id, 'day-rate');
    });

    testWidgets('tapping New equipment cost returns the new-cost result', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsNewEquipmentCost>());
    });

    testWidgets('swiping the sheet down returns dismissed', (tester) async {
      await openSheet(tester);

      await tester.fling(
        find.byKey(const Key('new_equipment_cost_row')),
        const Offset(0, 600),
        2000,
      );
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsDismissed>());
    });

    testWidgets('tapping outside the sheet returns dismissed', (tester) async {
      await openSheet(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsDismissed>());
    });

    testWidgets('the system back action returns dismissed', (tester) async {
      await openSheet(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsDismissed>());
    });
  });
}
