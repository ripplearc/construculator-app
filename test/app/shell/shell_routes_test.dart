import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_details_page.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_ui_provider.dart';
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

/// Regression tests for CA-900: pushes to the estimation and
/// project-settings destinations were silently swallowed while their
/// modules were registered as children of '/', because AppShellPage renders
/// no RouterOutlet for them to mount into. They are top-level routes now,
/// and these tests pin that a push actually lands on the destination page.
void main() {
  late FakeSupabaseWrapper fakeSupabaseWrapper;

  setUp(() {
    final fakeClock = FakeClockImpl();
    fakeSupabaseWrapper = FakeSupabaseWrapper(clock: fakeClock);

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

    final appBootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabaseWrapper,
    );

    Modular.init(ShellModule(appBootstrap));
    addTearDown(Modular.destroy);
    // Pre-bind DashboardModule so AuthNotifier, AuthManager, AppRouter, and
    // RecentEstimationsBloc are resolvable when AppShellPage is constructed.
    Modular.bindModule(DashboardModule(appBootstrap));

    Modular.replaceInstance<CurrentProjectNotifier>(
      FakeCurrentProjectNotifier(),
    );
    Modular.replaceInstance<ProjectUIProvider>(FakeProjectUIProvider());
  });

  tearDown(() {
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
}
