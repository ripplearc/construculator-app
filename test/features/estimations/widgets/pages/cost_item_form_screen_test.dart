import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/modular_pump_utils.dart';

class _CostItemFormScreenTestModule extends Module {
  final AppBootstrap appBootstrap;
  _CostItemFormScreenTestModule(this.appBootstrap);

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
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late AppBootstrap appBootstrap;
  late AppLocalizations l10n;

  const testEstimationId = 'test-estimation-id';
  const materialRoute = '$fullAddMaterialCostRoute/$testEstimationId';
  const labourRoute = '$fullAddLabourCostRoute/$testEstimationId';
  const equipmentRoute = '$fullAddEquipmentCostRoute/$testEstimationId';

  setUpAll(() {
    CoreToast.disableTimers();

    clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    appBootstrap = FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase);

    Modular.init(_CostItemFormScreenTestModule(appBootstrap));
    Modular.setInitialRoute(materialRoute);

    l10n = lookupAppLocalizations(const Locale('en'));
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  Widget makeApp() {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }


  void setUpAuthenticatedUser() {
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
  }

  group('CostItemFormScreen', () {
    testWidgets('renders material cost form screen', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      expect(find.byType(CostItemFormScreen), findsOneWidget);
    });

    testWidgets('renders labour cost form screen', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), labourRoute);

      expect(find.byType(CostItemFormScreen), findsOneWidget);
    });

    testWidgets('renders equipment cost form screen', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), equipmentRoute);

      expect(find.byType(CostItemFormScreen), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      expect(find.byKey(const Key('back_button')), findsOneWidget);
    });

    testWidgets('displays material cost screen title', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      expect(find.text(l10n.addMaterialCostsScreenTitle), findsOneWidget);
    });

    testWidgets('displays labour cost screen title', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), labourRoute);

      expect(find.text(l10n.addLabourCostsScreenTitle), findsOneWidget);
    });

    testWidgets('displays equipment cost screen title', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), equipmentRoute);

      expect(find.text(l10n.addEquipmentCostsScreenTitle), findsOneWidget);
    });

    testWidgets('displays mode toggle with manually selected by default', (
      tester,
    ) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      expect(find.byKey(const Key('mode_toggle_container')), findsOneWidget);
      expect(find.text(l10n.manuallyMode), findsOneWidget);
      expect(find.text(l10n.fromCostFileMode), findsOneWidget);
    });

    testWidgets('tapping from cost file pill switches mode', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      await tester.tap(find.byKey(const Key('from_cost_file_pill')));
      await tester.pump();

      final semantics = tester.getSemantics(
        find.byKey(const Key('from_cost_file_pill')),
      );
      expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('add to cost button is present and disabled initially', (
      tester,
    ) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      expect(find.byKey(const Key('add_to_cost_button')), findsOneWidget);
      final semantics = tester.getSemantics(
        find.byKey(const Key('add_to_cost_button')),
      );
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });

    testWidgets('displays edit title button', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      expect(find.byKey(const Key('edit_title_button')), findsOneWidget);
    });

    testWidgets('add to cost button enables after entering material type', (
      tester,
    ) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        'Lap Sealant',
      );
      await tester.pump();

      final semantics = tester.getSemantics(
        find.byKey(const Key('add_to_cost_button')),
      );
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
    });

    testWidgets('displays total label', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      expect(find.byKey(const Key('cost_item_total_label')), findsOneWidget);
    });

    testWidgets('displays how to calculate label in body', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, makeApp(), materialRoute);

      expect(
        find.byKey(const Key('how_to_calculate_label')),
        findsOneWidget,
      );
    });
  });
}
