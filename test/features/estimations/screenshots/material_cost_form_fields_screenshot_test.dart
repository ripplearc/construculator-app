
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
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

void main() {
  const size = Size(390.0, 300.0);
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;
  late FakeStorageService storage;
  late FakeAuthRepository auth;
  late MaterialCostFormBloc bloc;
  late FakeYourRatesDatabase database;

  setUpAll(() {
    final clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    storage = FakeStorageService();
    auth = FakeAuthRepository(clock: clock);
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<StorageService>(storage);
    Modular.replaceInstance<AuthRepository>(auth);
    database = FakeYourRatesDatabase();
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
  });

  tearDownAll(Modular.dispose);

  setUp(() async {
    fakeSupabase.reset();
    storage.reset();
    auth.reset();
    database.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    auth.setCurrentCredentials(
      UserCredential(
        id: 'account-1',
        email: 'a@example.com',
        metadata: const {},
        createdAt: DateTime(2026),
      ),
    );
    await loadAppFontsAll();
  });

  Future<void> pumpFields(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    bloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<MaterialCostFormBloc>.value(
            value: bloc,
            child: MaterialCostFormFields(
              yourRatesBlocFactory: Modular.get<YourRatesBloc>,
              clock: FakeClockImpl(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAllFields(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('material_name_field')),
      'Interior paint',
    );
    await tester.enterText(
      find.byKey(const Key('material_quantity_field')),
      '7',
    );
    await tester.enterText(find.byKey(const Key('material_rate_field')), '52');
    bloc.add(const MaterialUnitSelected(Unit.liters));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('MaterialCostFormFields Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders the empty form', (tester) async {
      await pumpFields(tester, theme);

      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/material_empty$suffix.png',
        ),
      );
    });

    testWidgets('renders the filled form', (tester) async {
      await pumpFields(tester, theme);
      await fillAllFields(tester);

      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/material_filled$suffix.png',
        ),
      );
    });

    Future<void> showSampleRate(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key('material_name_field')),
        'Interior paint · ProClassic',
      );
      await tester.enterText(
        find.byKey(const Key('material_quantity_field')),
        '7',
      );
      await tester.enterText(
        find.byKey(const Key('material_rate_field')),
        '52',
      );
      bloc.add(
        const MaterialSampleRatePicked(
          itemName: 'Interior paint · ProClassic',
          rate: 52,
          unit: Unit.liters,
          typedName: 'Interior paint',
        ),
      );
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();
    }

    Future<void> expectGolden(String name, String suffix) => expectLater(
      find.byType(MaterialCostFormFields),
      matchesGoldenFile('goldens/material_cost_form_fields/$name$suffix.png'),
    );

    testWidgets('renders a sample rate to verify: tag, link and save helper', (
      tester,
    ) async {
      await pumpFields(tester, theme);
      await showSampleRate(tester);

      await expectGolden('material_sample_rate', suffix);
    });

    testWidgets('renders a sample rate saved as the default', (tester) async {
      await pumpFields(tester, theme);
      await showSampleRate(tester);
      await tester.tap(find.byKey(const Key('save_as_default_link')));
      await tester.pumpAndSettle();

      await expectGolden('material_saved_as_default', suffix);
    });
  });
}
