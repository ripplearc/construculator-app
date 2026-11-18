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

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_your_rates_database.dart';
import '../../../../utils/your_rates_bloc_without_debounce.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late FakeClockImpl clock;

  setUpAll(() {
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

  tearDownAll(Modular.dispose);

  setUp(() {
    database.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    database.seedRow({
      'id': 'proclassic',
      'company_id': 'company-1',
      'category': 'material',
      'item_name': 'Interior paint ProClassic',
      'rate_amount': 52.0,
      'rate_currency': 'USD',
      'unit': 'liters',
      'saved_at': clock.now().toIso8601String(),
    });
  });

  tearDown(() {
    fakeSupabase.reset();
    database.reset();
  });

  Widget makeWidget(ThemeData theme) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<YourRatesBloc>(
        create: (_) => yourRatesBlocWithoutDebounce(),
        child: MaterialRateLookupSheet(
          initialQuery: 'interior paint',
          clock: clock,
        ),
      ),
    ),
  );

  Future<void> waitForSearch(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  group('MaterialRateLookupSheet – accessibility', () {
    testWidgets('a11y: a saved rate row meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(const Key('your_rate_row_proclassic')),
        setupAfterPump: waitForSearch,
      );
    });

    testWidgets('a11y: the search box meets tap target and label guidelines '
        'in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(const Key('your_rates_search_field')),
      );
    });

    testWidgets('a11y: the Use button meets tap target and label guidelines '
        'once a row is picked', (tester) async {
      await setupA11yTest(tester);
      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await waitForSearch(tester);
      await tester.tap(find.byKey(const Key('your_rate_row_proclassic')));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byKey(const Key('material_lookup_use_button')),
      );
    });
  });
}
