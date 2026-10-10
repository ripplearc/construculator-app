import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_recents_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    clock.set(DateTime(2026, 1, 15));
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

  group('YourRatesRecentsSheet – rows', () {
    testWidgets('lists the same-name day and job rows newest first, each with '
        'its own unit', (tester) async {
      await openSheet(tester);

      final dayRow = find.byKey(const Key('your_rate_row_day-rate'));
      final jobRow = find.byKey(const Key('your_rate_row_job-rate'));
      expect(
        tester.getTopLeft(dayRow).dy,
        lessThan(tester.getTopLeft(jobRow).dy),
      );
      expect(
        find.descendant(of: dayRow, matching: find.textContaining('/day')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: jobRow, matching: find.textContaining('job')),
        findsOneWidget,
      );
      expect(find.text('Scissor lift'), findsNWidgets(2));
    });

    testWidgets('counts calendar days: 4 pm yesterday seen at 9 am reads '
        '"Used yesterday"', (tester) async {
      clock.set(DateTime(2026, 1, 15, 9));
      fakeSupabase.addTableData('your_rates', [
        {
          'id': 'yesterday-rate',
          'company_id': 'company-1',
          'category': 'equipment',
          'item_name': 'Compactor',
          'rate_amount': 90,
          'rate_currency': 'USD',
          'equipment_method': 'day',
          'saved_at': DateTime(2026, 1, 14, 16).toIso8601String(),
        },
      ]);
      await openSheet(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('your_rate_row_yesterday-rate')),
          matching: find.text('Used yesterday'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the loading indicator before the rates arrive', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<YourRatesBloc>(
              create: (_) => Modular.get<YourRatesBloc>(),
              child: YourRatesRecentsSheet(clock: clock),
            ),
          ),
        ),
      );

      expect(find.byType(CoreLoadingIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CoreLoadingIndicator), findsNothing);
    });
  });

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

    testWidgets('shows a back arrow next to the Add equipment title', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.byKey(SheetHeader.backButtonKey), findsOneWidget);
      expect(find.text('Add equipment'), findsOneWidget);
    });

    testWidgets('tapping the back arrow returns dismissed', (tester) async {
      await openSheet(tester);

      await tester.tap(find.byKey(SheetHeader.backButtonKey));
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
