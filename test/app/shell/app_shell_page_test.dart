import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/global_search_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/sentry/fake_sentry_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late FakeAuthManager authManager;
  late FakeAuthNotifier authNotifier;
  late FakeCurrentProjectNotifier fakeProjectNotifier;
  late RecentEstimationsBloc recentEstimationsBloc;

  setUpAll(() {
    CoreToast.disableTimers();
  });

  tearDownAll(() {
    CoreToast.enableTimers();
  });

  setUp(() {
    final clock = FakeClockImpl();
    final fakeSupabase = FakeSupabaseWrapper(clock: clock);
    authNotifier = FakeAuthNotifier();
    authManager = FakeAuthManager(
      authNotifier: authNotifier,
      authRepository: FakeAuthRepository(clock: clock),
      wrapper: fakeSupabase,
      clock: clock,
    );
    fakeProjectNotifier = FakeCurrentProjectNotifier();
    recentEstimationsBloc = RecentEstimationsBloc(
      watchRecentEstimationsUseCase: WatchRecentEstimationsUseCase(
        FakeCostEstimationRepository(),
        fakeProjectNotifier,
      ),
      currentProjectNotifier: fakeProjectNotifier,
    );

    Modular.init(
      ShellModule(
        AppBootstrap(
          config: FakeAppConfig(),
          envLoader: FakeEnvLoader(),
          supabaseWrapper: fakeSupabase,
          sentryWrapper: FakeSentryWrapper(),
        ),
      ),
    );
    fakeProjectNotifier = FakeCurrentProjectNotifier();
    Modular.replaceInstance<CurrentProjectNotifier>(fakeProjectNotifier);
  });

  tearDown(() {
    recentEstimationsBloc.close();
    Modular.destroy();
  });

  BuildContext? buildContext;

  Widget makeApp({
    ProjectUIProvider? projectUIProvider,
    AppRouter? router,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        buildContext = context;
        return child!;
      },
      home: BlocProvider<AppShellBloc>(
        create: (_) => Modular.get<AppShellBloc>(),
        child: AppShellPage(
          projectUIProvider: projectUIProvider ?? _FakeProjectUIProvider(),
          authNotifier: authNotifier,
          authManager: authManager,
          router: router ?? FakeAppRouter(),
          recentEstimationsBloc: recentEstimationsBloc,
        ),
      ),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> tapTabByLabel(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
  }

  group('Tab Navigation', () {
    testWidgets('switches tabs and renders tab pages', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text(l10n().homeTab), findsAtLeastNWidgets(1));

      await tapTabByLabel(tester, l10n().calculationsTab);
      expect(find.text(l10n().calculationsTab), findsAtLeastNWidgets(1));

      await tapTabByLabel(tester, l10n().membersTab);
      expect(find.text(l10n().membersTab), findsAtLeastNWidgets(1));
    });

    testWidgets('bottom navigation bar is always visible', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(CoreBottomNavBar), findsOneWidget);

      for (final tabLabel in [l10n().calculationsTab, l10n().membersTab]) {
        await tapTabByLabel(tester, tabLabel);
        expect(find.byType(CoreBottomNavBar), findsOneWidget);
      }
    });

    testWidgets('lazy loads tabs on first access', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(CalculationsPage), findsNothing);
      expect(find.byType(MembersPage), findsNothing);

      await tapTabByLabel(tester, l10n().calculationsTab);
      expect(find.byType(CalculationsPage), findsOneWidget);

      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
    });
  });

  group('Tab State Preservation', () {
    testWidgets('tabs are only loaded on first access (lazy loading)', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(CalculationsPage, skipOffstage: false), findsNothing);
      expect(find.byType(MembersPage, skipOffstage: false), findsNothing);

      await tapTabByLabel(tester, l10n().calculationsTab);

      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(CalculationsPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(MembersPage, skipOffstage: false), findsNothing);

      await tapTabByLabel(tester, l10n().membersTab);

      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(CalculationsPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(MembersPage, skipOffstage: false), findsOneWidget);
    });

    testWidgets('preserves tab widget tree when switching away (no rebuild)', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      final dashboardElementBefore = tester.element(find.byType(DashboardPage));

      await tapTabByLabel(tester, l10n().calculationsTab);

      expect(find.byType(DashboardPage), findsNothing);
      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);

      await tapTabByLabel(tester, l10n().homeTab);

      final dashboardElementAfter = tester.element(find.byType(DashboardPage));

      expect(dashboardElementAfter, same(dashboardElementBefore));
    });

    testWidgets('all visited tabs remain mounted when switching between them', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tapTabByLabel(tester, l10n().calculationsTab);
      await tapTabByLabel(tester, l10n().membersTab);

      final dashboardElement = tester.element(
        find.byType(DashboardPage, skipOffstage: false),
      );
      final calculationsElement = tester.element(
        find.byType(CalculationsPage, skipOffstage: false),
      );
      final membersElement = tester.element(
        find.byType(MembersPage, skipOffstage: false),
      );

      await tapTabByLabel(tester, l10n().homeTab);
      await tapTabByLabel(tester, l10n().calculationsTab);
      await tapTabByLabel(tester, l10n().membersTab);

      expect(
        tester.element(find.byType(DashboardPage, skipOffstage: false)),
        same(dashboardElement),
      );
      expect(
        tester.element(find.byType(CalculationsPage, skipOffstage: false)),
        same(calculationsElement),
      );
      expect(
        tester.element(find.byType(MembersPage, skipOffstage: false)),
        same(membersElement),
      );
    });

    testWidgets('unvisited tabs remain unloaded after multiple switches', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tapTabByLabel(tester, l10n().calculationsTab);
      await tapTabByLabel(tester, l10n().homeTab);
      await tapTabByLabel(tester, l10n().calculationsTab);
      await tapTabByLabel(tester, l10n().homeTab);

      expect(find.byType(MembersPage, skipOffstage: false), findsNothing);
      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(CalculationsPage, skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('Cost Estimation Tab', () {
    testWidgets('shows CostEstimationLandingPage when estimation tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tapTabByLabel(tester, l10n().costEstimation);

      expect(find.byType(CostEstimationLandingPage), findsOneWidget);
    });
  });

  group('App Bar', () {
    testWidgets('shows static app title when no project is selected', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pump();

      expect(find.text(l10n().appTitle), findsAtLeastNWidgets(1));
    });

    testWidgets('hides static app title when a project id is set', (
      tester,
    ) async {
      fakeProjectNotifier.setCurrentProjectId(
        '950e8400-e29b-41d4-a716-446655440001',
      );
      await tester.pumpWidget(makeApp());
      await tester.pump();

      expect(find.text(l10n().appTitle), findsNothing);
    });

    testWidgets(
      'switches to project app bar when project id is emitted via stream',
      (tester) async {
        await tester.pumpWidget(makeApp());
        await tester.pump();
        expect(find.text(l10n().appTitle), findsAtLeastNWidgets(1));

        fakeProjectNotifier.setCurrentProjectId(
          '950e8400-e29b-41d4-a716-446655440001',
        );
        await tester.pump();

        expect(find.text(l10n().appTitle), findsNothing);
        expect(
          find.byKey(
            const Key(
              'project_app_bar_950e8400-e29b-41d4-a716-446655440001',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping search pushes the global search route', (
      tester,
    ) async {
      fakeProjectNotifier.setCurrentProjectId(
        '950e8400-e29b-41d4-a716-446655440001',
      );
      final fakeProvider = _FakeProjectUIProvider();
      final fakeRouter = FakeAppRouter();

      await tester.pumpWidget(
        makeApp(projectUIProvider: fakeProvider, router: fakeRouter),
      );
      await tester.pump();

      // Clear any initialization navigation (e.g. DashboardPage routing to login
      // or create-account when no authenticated user is set up in this test).
      fakeRouter.reset();

      final onSearchTap = fakeProvider.capturedOnSearchTap;
      if (onSearchTap == null) {
        fail('onSearchTap was not captured by the fake provider');
      }
      onSearchTap();
      await tester.pumpAndSettle();

      expect(fakeRouter.navigationHistory, [
        const RouteCall(fullGlobalSearchRoute, null),
      ]);
    });
  });
}

// TODO: [CA-724] Migrate to lib/libraries/project/testing/fake_project_ui_provider.dart
class _FakeProjectUIProvider extends ProjectUIProvider {
  VoidCallback? capturedOnSearchTap;

  @override
  PreferredSizeWidget buildProjectHeaderAppbar({
    required String projectId,
    VoidCallback? onProjectTap,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
  }) {
    capturedOnSearchTap = onSearchTap;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(key: Key('project_app_bar_$projectId')),
    );
  }
}
