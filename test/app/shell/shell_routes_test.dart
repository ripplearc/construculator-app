import 'package:construculator/app/app_module.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_details_page.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_ui_provider.dart';
import 'package:construculator/libraries/router/routes/calculator_routes.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../utils/fake_app_bootstrap_factory.dart';

/// Regression tests for CA-900: pushes to the estimation, project-settings,
/// and calculator destinations were silently swallowed while their modules
/// were registered as children of '/', because AppShellPage renders no
/// RouterOutlet for them to mount into. They are top-level routes now, and
/// these tests pin that a push actually lands on the destination page —
/// and that each route stays unreachable when signed out.
void main() {
  // One wrapper and bootstrap for the whole file, with per-test state resets
  // in setUp: modular_core's Tracker caches every imported module's injector
  // by runtimeType and never clears that cache on Modular.destroy, so binds
  // from imported modules (AuthManager, SupabaseWrapper, ...) capture the
  // FIRST test's bootstrap for the rest of the process. Creating a fresh
  // wrapper per test would leave the injector reading the first test's
  // instance while the test mutates its own — the signed-out tests below
  // would silently run signed-in.
  final fakeClock = FakeClockImpl();
  final fakeSupabaseWrapper = FakeSupabaseWrapper(clock: fakeClock);
  final appBootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: fakeSupabaseWrapper,
  );

  setUp(() {
    fakeSupabaseWrapper.reset();

    // An authenticated user, so every AuthGuard on the pushed routes passes.
    fakeSupabaseWrapper.setCurrentUser(
      FakeUser(id: 'fake-id', createdAt: fakeClock.now().toIso8601String()),
    );
    final fakeUser = User(
      id: '1',
      credentialId: 'fake-id',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'Engineer',
      createdAt: fakeClock.now(),
      updatedAt: fakeClock.now(),
      userStatus: UserProfileStatus.active,
      userPreferences: {},
    );
    fakeSupabaseWrapper.addTableData('users', [fakeUser.toJson()]);

    // Root the harness at AppModule so the module graph matches production
    // wiring exactly — path composition still resolves ShellModule at '/',
    // no manual module pre-binding is needed, and the AuthGuard's redirect
    // target (the /auth login route) exists for the signed-out tests below.
    Modular.init(AppModule(appBootstrap));

    Modular.replaceInstance<CurrentProjectNotifier>(
      FakeCurrentProjectNotifier(),
    );
    Modular.replaceInstance<ProjectUIProvider>(FakeProjectUIProvider());
  });

  tearDown(() {
    // Modular.routerConfig is never reset by Modular.destroy, so without
    // this the next test re-mounts THIS test's page stack against a fresh
    // injector and stale Modular.args. Clearing the delegate's configuration
    // returns it to the pristine state the first test of a run sees. The
    // setter only exists on the concrete ModularRouterDelegate, which
    // flutter_modular does not export — hence the dynamic cast.
    (Modular.routerConfig.routerDelegate as dynamic).currentConfiguration =
        null;
    Modular.destroy();
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

  // Bounded pumps instead of pumpAndSettle: shell sections may keep
  // loading indicators animating indefinitely against the empty fakes.
  Future<void> pumpShellAndPush(WidgetTester tester, String route) async {
    await tester.pumpWidget(makeApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    Modular.to.pushNamed(route);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets(
    'pushNamed to the estimation details route renders '
    'CostEstimationDetailsPage',
    (tester) async {
      await pumpShellAndPush(tester, '$fullEstimationDetailsRoute/est-123');

      expect(find.byType(CostEstimationDetailsPage), findsOneWidget);
    },
  );

  testWidgets(
    'pushNamed to the create-project route renders ProjectCreationScreen',
    (tester) async {
      await pumpShellAndPush(tester, createProjectRoute);

      expect(find.byType(ProjectCreationScreen), findsOneWidget);
    },
  );

  testWidgets(
    'pushNamed to the calculator route renders CalculatorPage',
    (tester) async {
      await pumpShellAndPush(tester, calculatorBaseRoute);

      expect(find.byType(CalculatorPage), findsOneWidget);
    },
  );

  // Signed-out variants: pin the guard coverage claim, not just rendering —
  // removing an AuthGuard from these routes must fail the suite.
  testWidgets(
    'pushNamed to the estimation details route does not render '
    'CostEstimationDetailsPage when signed out',
    (tester) async {
      fakeSupabaseWrapper.setCurrentUser(null);

      await pumpShellAndPush(tester, '$fullEstimationDetailsRoute/est-123');

      expect(find.byType(CostEstimationDetailsPage), findsNothing);
    },
  );

  testWidgets(
    'pushNamed to the create-project route does not render '
    'ProjectCreationScreen when signed out',
    (tester) async {
      fakeSupabaseWrapper.setCurrentUser(null);

      await pumpShellAndPush(tester, createProjectRoute);

      expect(find.byType(ProjectCreationScreen), findsNothing);
    },
  );

  testWidgets(
    'pushNamed to the calculator route does not render CalculatorPage '
    'when signed out',
    (tester) async {
      fakeSupabaseWrapper.setCurrentUser(null);

      await pumpShellAndPush(tester, calculatorBaseRoute);

      expect(find.byType(CalculatorPage), findsNothing);
    },
  );
}
