import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
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
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

class _CostItemFormScreenA11yTestModule extends Module {
  final AppBootstrap appBootstrap;
  _CostItemFormScreenA11yTestModule(this.appBootstrap);

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

  setUpAll(() {
    CoreToast.disableTimers();

    clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    appBootstrap = FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase);

    Modular.init(_CostItemFormScreenA11yTestModule(appBootstrap));
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

  Widget makeApp({ThemeData? theme}) {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      theme: theme ?? CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => child!,
    );
  }

  Future<void> pumpAppAtRoute(WidgetTester tester, String route) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      Modular.to.navigate(route);
      await Future.delayed(const Duration(milliseconds: 600));
    });
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
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

  group('CostItemFormScreen – accessibility', () {
    testWidgets('a11y: back button has label and tap target in both themes', (
      tester,
    ) async {
      setUpAuthenticatedUser();

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, materialRoute);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.bySemanticsLabel(l10n.closeLabel),
        setupAfterPump: (t) async {
          Modular.to.navigate(materialRoute);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('a11y: mode toggle meets tap target guidelines in both themes', (
      tester,
    ) async {
      setUpAuthenticatedUser();

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, materialRoute);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.byKey(const Key('mode_toggle_container')),
        checkTextContrast: false,
        setupAfterPump: (t) async {
          Modular.to.navigate(materialRoute);
          await t.pumpAndSettle();
        },
      );
    });
  });
}
