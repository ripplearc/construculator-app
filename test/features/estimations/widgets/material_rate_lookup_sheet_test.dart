import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_rate_lookup_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_your_rates_database.dart';
import '../../../utils/your_rates_bloc_without_debounce.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late FakeClockImpl clock;
  late AppLocalizations l10n;
  YourRateEntry? result;
  var closed = false;

  const useButton = Key('material_lookup_use_button');
  final searchField = find.descendant(
    of: find.byKey(const Key('your_rates_search_field')),
    matching: find.byType(EditableText),
  );

  setUpAll(() async {
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    database = FakeYourRatesDatabase();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  tearDownAll(Modular.dispose);

  Map<String, Object?> materialRow(
    String id,
    String name,
    double rate, {
    String? unit = 'liters',
  }) => {
    'id': id,
    'company_id': 'company-1',
    'category': 'material',
    'item_name': name,
    'rate_amount': rate,
    'rate_currency': 'USD',
    'unit': unit,
    'saved_at': clock.now().toIso8601String(),
  };

  setUp(() {
    result = null;
    closed = false;
    database.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    database.seedRows([
      materialRow('proclassic', 'Interior paint ProClassic', 52),
      materialRow('signature', 'Interior paint Signature', 45),
      materialRow('screws', 'Drywall screws', 18, unit: 'boxes'),
      {
        ...materialRow('lift', 'Interior paint lift', 120, unit: null),
        'category': 'equipment',
        'equipment_method': 'day',
      },
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
    database.reset();
  });

  Future<void> openSheet(
    WidgetTester tester, {
    String initialQuery = 'interior paint',
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
                  result = await MaterialRateLookupSheet.show(
                    context: context,
                    initialQuery: initialQuery,
                    clock: clock,
                    blocFactory: yourRatesBlocWithoutDebounce,
                  );
                  closed = true;
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

  Future<void> typeQuery(WidgetTester tester, String query) async {
    await tester.enterText(searchField, query);
    await tester.pumpAndSettle();
  }

  CoreButton useButtonWidget(WidgetTester tester) =>
      tester.widget<CoreButton>(find.byKey(useButton));

  group('MaterialRateLookupSheet – opening', () {
    testWidgets('opens on the material name, already searched', (tester) async {
      await openSheet(tester);

      expect(find.text('interior paint'), findsOneWidget);
      expect(find.text(l10n.yourRatesLookupTitle), findsOneWidget);
      expect(find.text('YOUR RATES'), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_proclassic')), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_signature')), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_screws')), findsNothing);
    });

    testWidgets('lists only material rates, never equipment ones', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.byKey(const Key('your_rate_row_lift')), findsNothing);
    });

    testWidgets('prices each row per its unit', (tester) async {
      await openSheet(tester, initialQuery: 'screws');

      expect(
        find.descendant(
          of: find.byKey(const Key('your_rate_row_screws')),
          matching: find.text('\$18.00 /Boxes', findRichText: true),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows a rate saved with no unit as its price alone', (
      tester,
    ) async {
      database.seedRows([materialRow('primer', 'PVA primer', 9.5, unit: null)]);
      await openSheet(tester, initialQuery: 'primer');

      expect(
        find.descendant(
          of: find.byKey(const Key('your_rate_row_primer')),
          matching: find.text('\$9.50', findRichText: true),
        ),
        findsOneWidget,
      );
    });

    testWidgets('clearing the box lists every saved material rate', (
      tester,
    ) async {
      await openSheet(tester);

      await typeQuery(tester, '');

      expect(find.byKey(const Key('your_rate_row_screws')), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_proclassic')), findsOneWidget);
    });
  });

  group('MaterialRateLookupSheet – picking', () {
    testWidgets('the button is greyed out as "Use rate" until a row is '
        'picked', (tester) async {
      await openSheet(tester);

      expect(useButtonWidget(tester).isDisabled, isTrue);
      expect(useButtonWidget(tester).label, l10n.materialLookupUseRateButton);
    });

    testWidgets('picking a row only selects it, and the button names its '
        'price', (tester) async {
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('your_rate_row_proclassic')));
      await tester.pumpAndSettle();

      expect(closed, isFalse);
      expect(useButtonWidget(tester).isDisabled, isFalse);
      expect(useButtonWidget(tester).label, r'Use $52.00 /Liters');
    });

    testWidgets('the button returns the picked rate and closes the sheet', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('your_rate_row_signature')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(useButton));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(
        result,
        isA<YourRateEntry>().having((entry) => entry.id, 'id', 'signature'),
      );
    });

    testWidgets('tapping the picked row again unpicks it', (tester) async {
      await openSheet(tester);
      final row = find.byKey(const Key('your_rate_row_proclassic'));

      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(useButtonWidget(tester).isDisabled, isTrue);
    });

    testWidgets('a search that drops the picked row greys the button again', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('your_rate_row_proclassic')));
      await tester.pumpAndSettle();

      await typeQuery(tester, 'signature');

      expect(useButtonWidget(tester).isDisabled, isTrue);
    });

    testWidgets('closing the sheet without the button returns nothing', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('your_rate_row_proclassic')));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
    });
  });

  group('MaterialRateLookupSheet – searching', () {
    testWidgets('keeps the previous rows on screen while a search runs, '
        'with no spinner', (tester) async {
      await openSheet(tester);
      final gate = Completer<void>();
      database.getAllGate = gate;

      await tester.enterText(searchField, 'drywall');
      await tester.pump();

      expect(find.byKey(const Key('your_rate_row_proclassic')), findsOneWidget);
      expect(find.byType(CoreLoadingIndicator), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('your_rate_row_screws')), findsOneWidget);
      expect(find.byKey(const Key('your_rate_row_proclassic')), findsNothing);
    });

    testWidgets('a search with no match shows one line, no rows, no button '
        'and no way to create an entry', (tester) async {
      await openSheet(tester);

      await typeQuery(tester, 'epoxy grout');

      expect(
        find.text(l10n.yourRatesNoMatchState('epoxy grout')),
        findsOneWidget,
      );
      expect(find.text('YOUR RATES'), findsNothing);
      expect(find.byKey(useButton), findsNothing);
      expect(find.textContaining('Create'), findsNothing);
    });
  });

  group('MaterialRateLookupSheet – saved prices cannot be read', () {
    testWidgets('shows the error row instead of saying nothing is saved', (
      tester,
    ) async {
      database.getAllError = StateError('database locked');
      await openSheet(tester);

      expect(find.byKey(const Key('your_rates_load_error')), findsOneWidget);
      expect(find.byKey(const Key('material_lookup_no_match')), findsNothing);
      expect(find.byKey(useButton), findsNothing);
    });

    testWidgets('Try again lists the rates once the read works', (
      tester,
    ) async {
      database.getAllError = StateError('database locked');
      await openSheet(tester);

      database.getAllError = null;
      await tester.tap(find.byKey(const Key('your_rates_try_again_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('your_rates_load_error')), findsNothing);
      expect(find.byKey(const Key('your_rate_row_proclassic')), findsOneWidget);
    });
  });
}
