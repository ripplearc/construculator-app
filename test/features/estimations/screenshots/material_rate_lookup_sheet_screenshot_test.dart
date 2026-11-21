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

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_your_rates_database.dart';
import '../../../utils/screenshot/font_loader.dart';
import '../../../utils/your_rates_bloc_without_debounce.dart';

void main() {
  const size = Size(390, 600);
  const ratio = 1.0;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late FakeClockImpl clock;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    database = FakeYourRatesDatabase();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
  });

  tearDownAll(Modular.destroy);

  setUp(() {
    fakeSupabase.reset();
    database.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    for (final (index, (id, name, amount)) in [
      ('proclassic', 'Interior paint · ProClassic', 52.0),
      ('signature', 'Interior paint · Signature', 45.0),
      ('contractor', 'Interior paint · Contractor Grade', 28.0),
    ].indexed) {
      database.seedRow({
        'id': id,
        'company_id': 'company-1',
        'category': 'material',
        'item_name': name,
        'rate_amount': amount,
        'rate_currency': 'USD',
        'unit': 'liters',
        'saved_at': clock
            .now()
            .subtract(Duration(days: index * 4))
            .toIso8601String(),
      });
    }
  });

  Future<void> pumpSheet(
    WidgetTester tester,
    ThemeData theme, {
    String initialQuery = 'interior paint',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
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

  Future<void> expectGolden(String name, String suffix) => expectLater(
    find.byType(MaterialRateLookupSheet),
    matchesGoldenFile(
      'goldens/material_rate_lookup_sheet/${size.width}x${size.height}/$name$suffix.png',
    ),
  );

  screenshotThemeGroups('MaterialRateLookupSheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('displays YOUR RATES with the button greyed out as Use rate', (
      tester,
    ) async {
      await pumpSheet(tester, theme);

      await expectGolden('results_none_picked', suffix);
    });

    testWidgets('displays the picked row and its price on the button', (
      tester,
    ) async {
      await pumpSheet(tester, theme);
      await tester.tap(find.byKey(const Key('your_rate_row_proclassic')));
      await tester.pumpAndSettle();

      await expectGolden('results_picked', suffix);
    });

    testWidgets('displays one no-match line and no button', (tester) async {
      await pumpSheet(tester, theme, initialQuery: 'epoxy grout');

      await expectGolden('no_match', suffix);
    });

    testWidgets('displays the error row when saved prices cannot be read', (
      tester,
    ) async {
      database.getAllError = StateError('database locked');
      await pumpSheet(tester, theme);

      await expectGolden('load_error', suffix);
    });
  });
}
