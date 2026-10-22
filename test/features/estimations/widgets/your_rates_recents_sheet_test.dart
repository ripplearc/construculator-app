import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_recents_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_your_rates_database.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late FakeClockImpl clock;
  YourRatesRecentsResult? result;

  setUpAll(() {
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    database = FakeYourRatesDatabase();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    result = null;
    database.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    clock.set(DateTime(2026, 1, 15));
    database.seedRows([
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
    database.reset();
  });

  int yourRatesReads() => database.getAllCalls
      .where((call) => call.sql.contains('your_rates'))
      .length;

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
      database.seedRows([
        {
          'id': 'yesterday-rate',
          'company_id': 'company-1',
          'category': 'equipment',
          'item_name': 'Compactor',
          'rate_amount': 90,
          'rate_currency': 'USD',
          'equipment_method': 'day',
          'saved_at': DateTime(2026, 1, 1).toIso8601String(),
          'last_used_at': DateTime(2026, 1, 14, 16).toIso8601String(),
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

    testWidgets('a rate never added to an estimate reads "Saved …", not '
        '"Used …"', (tester) async {
      clock.set(DateTime(2026, 1, 15, 9));
      database.seedRows([
        {
          'id': 'never-added-rate',
          'company_id': 'company-1',
          'category': 'equipment',
          'item_name': 'Compactor',
          'rate_amount': 90,
          'rate_currency': 'USD',
          'equipment_method': 'day',
          'saved_at': DateTime(2026, 1, 15, 8).toIso8601String(),
        },
      ]);
      await openSheet(tester);

      final row = find.byKey(const Key('your_rate_row_never-added-rate'));
      expect(
        find.descendant(of: row, matching: find.text('Saved today')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.textContaining('Used')),
        findsNothing,
      );
    });

    testWidgets('puts a rate used after a newer save above that save', (
      tester,
    ) async {
      clock.set(DateTime(2026, 1, 15, 9));
      database.seedRows([
        {
          'id': 'saved-later-rate',
          'company_id': 'company-1',
          'category': 'equipment',
          'item_name': 'Compactor',
          'rate_amount': 90,
          'rate_currency': 'USD',
          'equipment_method': 'day',
          'saved_at': DateTime(2026, 1, 10).toIso8601String(),
        },
        {
          'id': 'used-today-rate',
          'company_id': 'company-1',
          'category': 'equipment',
          'item_name': 'Excavator',
          'rate_amount': 250,
          'rate_currency': 'USD',
          'equipment_method': 'day',
          'saved_at': DateTime(2025, 12, 1).toIso8601String(),
          'last_used_at': DateTime(2026, 1, 15, 8).toIso8601String(),
        },
      ]);
      await openSheet(tester);

      final usedToday = find.byKey(const Key('your_rate_row_used-today-rate'));
      final savedLater = find.byKey(
        const Key('your_rate_row_saved-later-rate'),
      );
      expect(
        tester.getTopLeft(usedToday).dy,
        lessThan(tester.getTopLeft(savedLater).dy),
      );
      expect(
        find.descendant(of: usedToday, matching: find.text('Used today')),
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

  group('YourRatesRecentsSheet – saved prices cannot be read', () {
    const errorKey = Key('your_rates_recents_load_error');
    const tryAgainKey = Key('your_rates_recents_try_again_button');

    Future<void> openFailedSheet(WidgetTester tester) async {
      database.getAllError = StateError('database locked');
      await openSheet(tester);
    }

    testWidgets('shows the error line, the grey line and Try again instead of '
        'an empty list', (tester) async {
      await openFailedSheet(tester);

      expect(find.byKey(errorKey), findsOneWidget);
      expect(find.text('Couldn’t open your saved prices.'), findsOneWidget);
      expect(
        find.text('You can still search, or add a new equipment cost.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byKey(const Key('your_rates_recents_list')), findsNothing);
      expect(find.textContaining('No saved rates'), findsNothing);
    });

    testWidgets('New equipment cost still opens the empty form', (
      tester,
    ) async {
      await openFailedSheet(tester);

      await tester.tap(find.byKey(const Key('new_equipment_cost_row')));
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsNewEquipmentCost>());
    });

    testWidgets('Try again replaces the message with the recent list when the '
        'read works', (tester) async {
      await openFailedSheet(tester);
      database.getAllError = null;

      await tester.tap(find.byKey(tryAgainKey));
      await tester.pumpAndSettle();

      expect(find.byKey(errorKey), findsNothing);
      expect(find.byKey(const Key('your_rate_row_day-rate')), findsOneWidget);
    });

    testWidgets('keeps the message when Try again fails again, and the button '
        'works again', (tester) async {
      await openFailedSheet(tester);

      await tester.tap(find.byKey(tryAgainKey));
      await tester.pumpAndSettle();

      expect(find.byKey(errorKey), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_day-rate')), findsNothing);

      database.getAllError = null;
      await tester.tap(find.byKey(tryAgainKey));
      await tester.pumpAndSettle();

      expect(find.byKey(errorKey), findsNothing);
      expect(find.byKey(const Key('your_rate_row_day-rate')), findsOneWidget);
    });

    testWidgets('while Try again runs, the label stays, there is no spinner '
        'and a second tap reads nothing', (tester) async {
      await openFailedSheet(tester);
      database.getAllError = null;
      database.getAllGate = Completer<void>();
      final readsBefore = yourRatesReads();

      await tester.tap(find.byKey(tryAgainKey));
      await tester.pump();
      await tester.tap(find.byKey(tryAgainKey));
      await tester.pump();

      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(CoreLoadingIndicator), findsNothing);
      expect(yourRatesReads(), readsBefore + 1);

      database.getAllGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('Try again with a typed name keeps the label, the Create row '
        'and no spinner, and reads at once', (tester) async {
      await openFailedSheet(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('your_rates_search_field')),
          matching: find.byType(EditableText),
        ),
        'scissor',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(errorKey), findsOneWidget);
      database.getAllError = null;
      database.getAllGate = Completer<void>();
      final readsBefore = yourRatesReads();

      await tester.tap(find.byKey(tryAgainKey));
      await tester.pump();

      expect(yourRatesReads(), readsBefore + 1);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(CoreLoadingIndicator), findsNothing);
      expect(
        find.byKey(const Key('create_typed_equipment_row')),
        findsOneWidget,
      );

      database.getAllGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('does not show the message when the read works', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.byKey(errorKey), findsNothing);
    });
  });
  group('YourRatesRecentsSheet – search', () {
    final searchField = find.descendant(
      of: find.byKey(const Key('your_rates_search_field')),
      matching: find.byType(EditableText),
    );

    Future<void> typeQuery(WidgetTester tester, String query) async {
      await tester.enterText(searchField, query);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    testWidgets('a typed name lists the matching rates under YOUR RATES', (
      tester,
    ) async {
      database.seedRows([
        {
          'id': 'compactor-rate',
          'company_id': 'company-1',
          'category': 'equipment',
          'item_name': 'Compactor',
          'rate_amount': 90,
          'rate_currency': 'USD',
          'equipment_method': 'day',
          'saved_at': clock.now().toIso8601String(),
        },
      ]);
      await openSheet(tester);

      await typeQuery(tester, 'compactor');

      expect(find.text('YOUR RATES'), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_compactor-rate')), findsOne);
      expect(find.byKey(const Key('your_rate_row_day-rate')), findsNothing);
    });

    testWidgets('the last row offers to create the typed name', (tester) async {
      await openSheet(tester);

      await typeQuery(tester, 'mini excavator');
      await tester.tap(find.byKey(const Key('create_typed_equipment_row')));
      await tester.pumpAndSettle();

      expect(
        find.text('Create “mini excavator” as a new equipment cost'),
        findsNothing,
      );
      expect(result, isA<YourRatesRecentsNewEquipmentCost>());
      expect(
        (result! as YourRatesRecentsNewEquipmentCost).name,
        'mini excavator',
      );
    });

    testWidgets(
      'a name with no match shows one line and keeps the Create row',
      (tester) async {
        await openSheet(tester);

        await typeQuery(tester, 'stump grinder');

        expect(find.text('No matches for “stump grinder”'), findsOneWidget);
        expect(find.text('YOUR RATES'), findsNothing);
        expect(
          find.text('Create “stump grinder” as a new equipment cost'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('new_equipment_cost_row')), findsNothing);
      },
    );

    testWidgets(
      'a name with no match is centred, with 24 dp above and 32 dp below',
      (tester) async {
        await openSheet(tester);

        await typeQuery(tester, 'stump grinder');

        final line = find.text('No matches for “stump grinder”');
        expect(tester.widget<Text>(line).textAlign, TextAlign.center);
        final box = tester.getRect(
          find.byKey(const Key('your_rates_recents_no_match')),
        );
        final text = tester.getRect(line);
        expect(text.top - box.top, 24);
        expect(box.bottom - text.bottom, 32);
      },
    );

    testWidgets('keeps the rows and the Create row on screen while a search '
        'runs', (tester) async {
      await openSheet(tester);
      await typeQuery(tester, 'scissor');
      expect(find.byKey(const Key('your_rate_row_day-rate')), findsOneWidget);
      database.getAllGate = Completer<void>();

      BlocProvider.of<YourRatesBloc>(
        tester.element(find.byType(YourRatesRecentsSheet)),
      ).add(
        const YourRatesRecentsQueried(
          'scissor',
          CostItemType.equipment,
          immediate: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('your_rates_recents_searching')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('your_rate_row_day-rate')), findsOneWidget);
      expect(
        find.byKey(const Key('create_typed_equipment_row')),
        findsOneWidget,
      );

      database.getAllGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('Create on a name that is already saved opens its saved price, '
        'on the method used last', (tester) async {
      await openSheet(tester);

      await typeQuery(tester, 'SCISSOR LIFT');
      await tester.tap(find.byKey(const Key('create_typed_equipment_row')));
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsPicked>());
      expect((result! as YourRatesRecentsPicked).entry.id, 'day-rate');
    });

    testWidgets('Create tapped inside the search wait on a saved name still '
        'opens its saved price, on the method used last', (tester) async {
      await openSheet(tester);

      await tester.enterText(searchField, 'Scissor lift');
      await tester.pump();
      await tester.tap(find.byKey(const Key('create_typed_equipment_row')));
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsPicked>());
      expect((result! as YourRatesRecentsPicked).entry.id, 'day-rate');
    });

    testWidgets('Create tapped inside the search wait on a name that is not '
        'saved opens the form with just the name', (tester) async {
      await openSheet(tester);

      await tester.enterText(searchField, 'stump grinder');
      await tester.pump();
      await tester.tap(find.byKey(const Key('create_typed_equipment_row')));
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsNewEquipmentCost>());
      expect(
        (result! as YourRatesRecentsNewEquipmentCost).name,
        'stump grinder',
      );
    });

    testWidgets('Create on a name that is not saved opens the form with just '
        'the name', (tester) async {
      await openSheet(tester);

      await typeQuery(tester, 'scissor');
      await tester.tap(find.byKey(const Key('create_typed_equipment_row')));
      await tester.pumpAndSettle();

      expect(result, isA<YourRatesRecentsNewEquipmentCost>());
      expect((result! as YourRatesRecentsNewEquipmentCost).name, 'scissor');
    });

    testWidgets('clearing the box shows the recents and the New row again', (
      tester,
    ) async {
      await openSheet(tester);
      await typeQuery(tester, 'stump grinder');

      await tester.tap(find.bySemanticsLabel('Clear search'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('your_rate_row_day-rate')), findsOneWidget);
      expect(find.byKey(const Key('new_equipment_cost_row')), findsOneWidget);
      expect(find.byKey(const Key('create_typed_equipment_row')), findsNothing);
    });

    testWidgets('spaces alone are not a name', (tester) async {
      await openSheet(tester);

      await typeQuery(tester, '   ');

      expect(find.byKey(const Key('new_equipment_cost_row')), findsOneWidget);
      expect(find.byKey(const Key('create_typed_equipment_row')), findsNothing);
    });
  });
}
