import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_your_rates_database.dart';
import '../../../utils/screenshot/font_loader.dart';
import '../helpers/cost_item_test_data_map_factory.dart';

class _EstimateScreenTestModule extends Module {
  final AppBootstrap appBootstrap;
  _EstimateScreenTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    ProjectModule(appBootstrap),
    AuthLibraryModule(appBootstrap),
  ];

  @override
  void routes(RouteManager r) {
    r.module(estimationBaseRoute, module: EstimationRoutesModule(appBootstrap));
  }
}

void main() {
  const size = Size(412, 900);
  const estimationId = 'test-estimation-id';
  const route = '$fullEstimationDetailsRoute/$estimationId';
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late Clock clock;

  setUpAll(() {
    CoreToast.disableTimers();
    clock = FakeClockImpl();
    database = FakeYourRatesDatabase();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final appBootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(_EstimateScreenTestModule(appBootstrap));
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
    Modular.setInitialRoute(route);
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() async {
    await loadAppFontsAll();
    fakeSupabase.reset();
    database.reset();
    Modular.dispose<AuthManager>();
    Modular.dispose<CurrentCompanyResolver>();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    fakeSupabase.setRpcResponse(
      DatabaseConstants.ensureMyCompanyRpcFunction,
      'company-1',
    );
    Modular.get<AuthManager>();
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: 'test-credential-id',
        email: 'test@example.com',
        createdAt: clock.now().toIso8601String(),
      ),
    );
    fakeSupabase.addTableData('users', [
      {
        'id': 'user-1',
        'credential_id': 'test-credential-id',
        'email': 'test@example.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'professional_role': 'Engineer',
        'profile_photo_url': null,
        'created_at': clock.now().toIso8601String(),
        'updated_at': clock.now().toIso8601String(),
        'user_status': 'active',
        'user_preferences': {'': ''},
      },
    ]);
    fakeSupabase.addTableData(DatabaseConstants.costEstimatesTable, [
      EstimationTestDataMapFactory.createFakeEstimationData(
        id: estimationId,
        estimateName: 'Bedroom 2',
        totalCost: 0,
      ),
    ]);
  });

  Future<void> pumpScreen(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: Modular.routerConfig,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    Modular.to.navigate(route);
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('Cost estimation details page Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('an empty estimate', (tester) async {
      await pumpScreen(tester, theme);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/cost_estimation_details_page/empty$suffix.png',
        ),
      );
    });

    testWidgets('lines in all three sections', (tester) async {
      fakeSupabase.addTableData(DatabaseConstants.costItemsTable, [
        CostItemTestDataMapFactory.createMaterialItemData(
          id: 'm1',
          estimateId: estimationId,
          itemName: 'Drywall sheets',
          itemTotalCost: 211.34,
        ),
        CostItemTestDataMapFactory.createLaborItemData(
          id: 'l1',
          estimateId: estimationId,
          itemName: 'Framing crew',
          itemTotalCost: 480,
        ),
        CostItemTestDataMapFactory.createEquipmentItemData(
          id: 'q1',
          estimateId: estimationId,
          itemName: 'Scissor lift',
          itemTotalCost: 665,
        ),
      ]);
      await pumpScreen(tester, theme);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/cost_estimation_details_page/three_sections$suffix.png',
        ),
      );
    });

    testWidgets('the cost lines fail to load', (tester) async {
      fakeSupabase.shouldThrowOnSelectMatch = true;
      fakeSupabase.selectMatchExceptionType = SupabaseExceptionType.socket;
      await pumpScreen(tester, theme);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/cost_estimation_details_page/load_failed$suffix.png',
        ),
      );
    });
  });
}
