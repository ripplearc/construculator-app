import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../helpers/estimation_test_data_map_factory.dart';
import '../../../../utils/a11y/a11y_guidelines.dart';

class _CostEstimationLandingPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;

  _CostEstimationLandingPageA11yTestModule(this.appBootstrap);

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

  const testEstimationRoute = '$fullEstimationLandingRoute/$testProjectId';
  BuildContext? buildContext;

  setUpAll(() {
    CoreToast.disableTimers();

    clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);

    appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(_CostEstimationLandingPageA11yTestModule(appBootstrap));
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
      builder: (context, child) {
        buildContext = context;
        return child!;
      },
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

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

  void addCostEstimationData(Map<String, dynamic> estimationData) {
    fakeSupabase.addTableData('cost_estimates', [estimationData]);
  }

  group('CostEstimationLandingPage – accessibility', () {
    testWidgets('meets a11y guidelines for add estimation button in both themes',
        (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, testEstimationRoute);
      final addLabel = l10n().addEstimation;
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.text(addLabel),
        setupAfterPump: (t) async {
          Modular.to.navigate(testEstimationRoute);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets(
        'meets a11y guidelines for add estimation button with list in both themes',
        (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Kitchen Remodel',
        ),
      );

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, testEstimationRoute);
      final addLabel = l10n().addEstimation;
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.text(addLabel),
        setupAfterPump: (t) async {
          Modular.to.navigate(testEstimationRoute);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets(
        'meets a11y guidelines for error toast close button in both themes',
        (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      fakeSupabase.shouldThrowOnSelectMultiple = true;
      fakeSupabase.selectMultipleExceptionType = SupabaseExceptionType.timeout;

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, testEstimationRoute);
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.byKey(const Key('toast_close_button')),
        setupAfterPump: (t) async {
          Modular.to.navigate(testEstimationRoute);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets(
        'meets a11y guidelines for delete confirmation yes button in both themes',
        (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Kitchen Remodel',
        ),
      );

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, testEstimationRoute);
      final yesLabel = l10n().yesDeleteButton;
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.text(yesLabel),
        setupAfterPump: (t) async {
          Modular.to.navigate(testEstimationRoute);
          await t.pumpAndSettle();
          final menuFinder = find.byKey(const Key('menuIcon'));
          await t.ensureVisible(menuFinder);
          await t.tapAt(t.getCenter(menuFinder));
          await t.pumpAndSettle();
          await t.tap(find.text(l10n().removeAction));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets(
        'meets a11y guidelines for delete confirmation no button in both themes',
        (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Kitchen Remodel',
        ),
      );

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, testEstimationRoute);
      final noLabel = l10n().noKeepButton;
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.text(noLabel),
        setupAfterPump: (t) async {
          Modular.to.navigate(testEstimationRoute);
          await t.pumpAndSettle();
          final menuFinder = find.byKey(const Key('menuIcon'));
          await t.ensureVisible(menuFinder);
          await t.tapAt(t.getCenter(menuFinder));
          await t.pumpAndSettle();
          await t.tap(find.text(l10n().removeAction));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets(
        'meets a11y guidelines for estimation tile menu icon in both themes',
        (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Kitchen Remodel',
        ),
      );

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, testEstimationRoute);
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.byKey(const Key('menuIcon')),
        // checkTextContrast: false,
        setupAfterPump: (t) async {
          Modular.to.navigate(testEstimationRoute);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets(
        'meets a11y guidelines for estimation tile tap target in both themes',
        (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Kitchen Remodel',
        ),
      );

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, testEstimationRoute);
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.byKey(const Key('tileGestureDetector')),
        checkTextContrast: false,
        setupAfterPump: (t) async {
          Modular.to.navigate(testEstimationRoute);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets(
        'meets a11y text contrast for empty state message in both themes',
        (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await setupA11yTest(tester);
      await pumpAppAtRoute(tester, testEstimationRoute);
      final emptyMessage = l10n().costEstimationEmptyMessage;
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeApp(theme: theme),
        find.text(emptyMessage),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
        setupAfterPump: (t) async {
          Modular.to.navigate(testEstimationRoute);
          await t.pumpAndSettle();
        },
      );
    });
  });
}