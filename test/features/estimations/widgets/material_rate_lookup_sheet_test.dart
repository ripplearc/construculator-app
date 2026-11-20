import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_rate_lookup_sheet.dart';
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
import '../../../utils/your_rates_bloc_without_debounce.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late FakeClockImpl clock;
  late AppLocalizations l10n;
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
        home: Scaffold(
          body: BlocProvider<YourRatesBloc>(
            create: (_) => yourRatesBlocWithoutDebounce(),
            child: MaterialRateLookupSheet(
              initialQuery: initialQuery,
              clock: clock,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeQuery(WidgetTester tester, String query) async {
    await tester.enterText(searchField, query);
    await tester.pumpAndSettle();
  }

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

    testWidgets('leaves out the YOUR RATES heading when no rate matches', (
      tester,
    ) async {
      await openSheet(tester);

      await typeQuery(tester, 'epoxy grout');

      expect(find.text('YOUR RATES'), findsNothing);
      expect(find.byKey(const Key('your_rate_row_proclassic')), findsNothing);
    });
  });
}
