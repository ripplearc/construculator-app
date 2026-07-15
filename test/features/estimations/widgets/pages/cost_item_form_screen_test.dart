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

  Future<void> pumpAppAtRoute(WidgetTester tester, String route) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();
    Modular.to.navigate(route);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
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
      await pumpAppAtRoute(tester, materialRoute);

      expect(find.byType(CostItemFormScreen), findsOneWidget);
    });

    testWidgets('renders labour cost form screen', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, labourRoute);

      expect(find.byType(CostItemFormScreen), findsOneWidget);
    });

    testWidgets('renders equipment cost form screen', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, equipmentRoute);

      expect(find.byType(CostItemFormScreen), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      expect(find.byKey(const Key('back_button')), findsOneWidget);
    });

    testWidgets('displays material cost screen title', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      expect(find.text(l10n.addMaterialCostsScreenTitle), findsOneWidget);
    });

    testWidgets('displays labour cost screen title', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, labourRoute);

      expect(find.text(l10n.addLabourCostsScreenTitle), findsOneWidget);
    });

    testWidgets('displays equipment cost screen title', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, equipmentRoute);

      expect(find.text(l10n.addEquipmentCostsScreenTitle), findsOneWidget);
    });

    testWidgets('displays mode toggle with manually selected by default', (
      tester,
    ) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      expect(find.byKey(const Key('mode_toggle_container')), findsOneWidget);
      expect(find.text(l10n.manuallyMode), findsOneWidget);
      expect(find.text(l10n.fromCostFileMode), findsOneWidget);
    });

    testWidgets('tapping from cost file pill switches mode', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      await tester.tap(find.byKey(const Key('from_cost_file_pill')));
      await tester.pump();

      final semantics = tester.getSemantics(
        find.byKey(const Key('from_cost_file_pill')),
      );
      expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('displays add to cost button disabled', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      final button = tester.widget<CoreButton>(
        find.byKey(const Key('add_to_cost_button')),
      );
      expect(button.isDisabled, isTrue);
    });

    testWidgets('displays edit title button', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      expect(find.byKey(const Key('edit_title_button')), findsOneWidget);
    });

    testWidgets('displays total label', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      expect(find.byKey(const Key('cost_item_total_label')), findsOneWidget);
    });

    testWidgets('displays how to calculate label in body', (tester) async {
      setUpAuthenticatedUser();
      await pumpAppAtRoute(tester, materialRoute);

      expect(
        find.byKey(const Key('how_to_calculate_label')),
        findsOneWidget,
      );
    });
  });
}
