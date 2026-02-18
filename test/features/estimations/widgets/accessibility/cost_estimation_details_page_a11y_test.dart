import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
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

class _CostEstimationDetailsPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;

  _CostEstimationDetailsPageA11yTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    ProjectModule(appBootstrap),
    AuthLibraryModule(appBootstrap),
  ];

  @override
  void routes(RouteManager r) {
    r.module(estimationBaseRoute, module: EstimationModule(appBootstrap));
  }
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late AppBootstrap appBootstrap;

  const testEstimationId = 'test-estimation-id';
  const testEstimationRoute = '$fullEstimationDetailsRoute/$testEstimationId';

  setUpAll(() {
    CoreToast.disableTimers();

    clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);

    appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(_CostEstimationDetailsPageA11yTestModule(appBootstrap));
    Modular.setInitialRoute(testEstimationRoute);
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
    Modular.to.navigate(route);
    await tester.pumpAndSettle();
  }

  void setUpAuthenticatedUser({
    required String credentialId,
    required String email,
    String userId = 'user-1',
    String? profilePhotoUrl,
  }) {
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: credentialId,
        email: email,
        createdAt: clock.now().toIso8601String(),
      ),
    );

    fakeSupabase.addTableData('users', [
      {
        'id': userId,
        'credential_id': credentialId,
        'email': email,
        'first_name': 'John',
        'last_name': 'Doe',
        'professional_role': 'Engineer',
        'profile_photo_url': profilePhotoUrl,
        'created_at': clock.now().toIso8601String(),
        'updated_at': clock.now().toIso8601String(),
        'user_status': 'active',
        'user_preferences': {'': ''},
      },
    ]);
  }

  group('CostEstimationDetailsPage – accessibility', () {
    testWidgets(
      'meets a11y text contrast for coming soon message in both themes',
      (tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await setupA11yTest(tester);
        await pumpAppAtRoute(tester, testEstimationRoute);

        const comingSoonText =
            'Cost estimation details will be available in a future update.';
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeApp(theme: theme),
          find.text(comingSoonText),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
          setupAfterPump: (t) async {
            Modular.to.navigate(testEstimationRoute);
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y text contrast for app bar title in both themes',
      (tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await setupA11yTest(tester);
        await pumpAppAtRoute(tester, testEstimationRoute);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeApp(theme: theme),
          find.text('Estimation Details'),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
          setupAfterPump: (t) async {
            Modular.to.navigate(testEstimationRoute);
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y text contrast for estimation ID text in both themes',
      (tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await setupA11yTest(tester);
        await pumpAppAtRoute(tester, testEstimationRoute);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeApp(theme: theme),
          find.text('Estimation ID: $testEstimationId'),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
          setupAfterPump: (t) async {
            Modular.to.navigate(testEstimationRoute);
            await t.pumpAndSettle();
          },
        );
      },
    );
  });
}
