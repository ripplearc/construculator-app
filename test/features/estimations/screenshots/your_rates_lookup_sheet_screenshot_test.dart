import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_lookup_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 500);
  const ratio = 1.0;
  const table = 'your_rates';
  late FakeSupabaseWrapper fakeSupabase;
  late List<Map<String, dynamic>> seededRows;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFonts();
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    fakeSupabase.reset();
    seededRows = [];
    // CurrentCompanyResolverImpl caches its result for the resolver's own
    // lifetime, which outlives a single test here (it's a lazy singleton
    // shared across this file's setUpAll'd Modular instance) — clear it so
    // each test starts from a fresh, un-resolved session.
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
  });

  // Seeds a `your_rates` row directly on the fake backend rather than going
  // through `YourRatesRepository.save()`: `YourRateEntryDto.toJson()`
  // deliberately omits `description` today, since the real `your_rates`
  // table has no matching column yet (see that DTO's class doc comment) —
  // a save() round-trip would silently drop it, same as production. Seeding
  // the row directly is how this test exercises the row's description
  // rendering ahead of that backend column landing.
  void seedRate({
    required String itemName,
    required double amount,
    String? description,
  }) {
    seededRows = [
      ...seededRows,
      {
        'id': 'rate-${seededRows.length + 1}',
        'company_id': 'company-1',
        'category': 'equipment',
        'item_name': itemName,
        'rate_amount': amount,
        'rate_currency': 'USD',
        'equipment_method': 'job',
        'saved_at': DateTime(2026, 1, 1).toIso8601String(),
        'description': ?description,
      },
    ];
    fakeSupabase.addTableData(table, seededRows);
  }

  Future<void> pumpSheet({
    required WidgetTester tester,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<YourRatesBloc>(
            create: (_) => Modular.get<YourRatesBloc>(),
            child: const YourRatesLookupSheet(
              method: EquipmentPricingMethod.job,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('YourRatesLookupSheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('displays the empty state when nothing is saved yet', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(YourRatesLookupSheet),
        matchesGoldenFile(
          'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/empty$suffix.png',
        ),
      );
    });

    testWidgets('displays result rows, one with a description', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      seedRate(
        itemName: 'Mini excavator — 1.5 ton',
        amount: 520,
        description: 'Quoted for the whole dig, machine + operator',
      );
      seedRate(itemName: 'Excavator + operator — half day', amount: 340);

      await pumpSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(YourRatesLookupSheet),
        matchesGoldenFile(
          'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/results$suffix.png',
        ),
      );
    });

    testWidgets(
      'shows the check, highlight, and confirm button once a row is selected',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(
          itemName: 'Mini excavator — 1.5 ton',
          amount: 520,
          description: 'Quoted for the whole dig, machine + operator',
        );

        await pumpSheet(tester: tester, theme: theme);
        await tester.tap(find.text('Mini excavator — 1.5 ton'));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(YourRatesLookupSheet),
          matchesGoldenFile(
            'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/selected$suffix.png',
          ),
        );
      },
    );
  });
}
