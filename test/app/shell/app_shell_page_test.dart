import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/default_tab_providers.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/sentry/fake_sentry_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class _FakeProjectUiProvider extends ProjectUIProvider {
  @override
  PreferredSizeWidget buildProjectHeaderAppbar({
    required String projectId,
    VoidCallback? onProjectTap,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
    ImageProvider<Object>? avatarImage,
  }) {
    return AppBar(title: Text(projectId));
  }
}

class _TestEstimationTabModuleProvider implements TabModuleProvider {
  const _TestEstimationTabModuleProvider();

  @override
  Future<void> load(AppBootstrap appBootstrap) async {
    Modular.bindModule(EstimationModule(appBootstrap));
  }
}

class _AppShellTestModule extends Module {
  final FakeAuthManager authManager;
  final FakeAuthNotifier authNotifier;
  final FakeCurrentProjectNotifier currentProjectNotifier;
  final AppBootstrap appBootstrap;

  _AppShellTestModule({
    required this.authManager,
    required this.authNotifier,
    required this.currentProjectNotifier,
    required this.appBootstrap,
  });

  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthManager>(() => authManager);
    i.addLazySingleton<AuthNotifier>(() => authNotifier);
    i.add<AppShellBloc>(AppShellBloc.new);
    i.add<ProjectDropdownBloc>(
      () => ProjectDropdownBloc(
        projectRepository: FakeProjectRepository(),
        authManager: authManager,
      ),
    );
    i.addLazySingleton<AppRouter>(FakeAppRouter.new);
    i.addLazySingleton<CurrentProjectNotifier>(() => currentProjectNotifier);
    i.addLazySingleton<ProjectUIProvider>(() => _FakeProjectUiProvider());
    i.addLazySingleton<TabModuleManager>(
      () => TabModuleManager(
        appBootstrap,
        providers: {
          for (final tab in ShellTab.values) tab: const NoOpTabModuleProvider(),
          ShellTab.estimation: const _TestEstimationTabModuleProvider(),
        },
      ),
    );
    i.add<AppShellBloc>(() => AppShellBloc(moduleLoader: i.get()));
  }
}

void main() {
  late FakeCurrentProjectNotifier fakeProjectNotifier;

  setUpAll(() {
    CoreToast.disableTimers();
  });

  tearDownAll(() {
    CoreToast.enableTimers();
  });

  setUp(() {
    final clock = FakeClockImpl();
    final fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final authNotifier = FakeAuthNotifier();
    final authRepository = FakeAuthRepository(clock: clock);
    final authManager = FakeAuthManager(
      authNotifier: authNotifier,
      authRepository: authRepository,
      wrapper: fakeSupabase,
      clock: clock,
    );
    fakeProjectNotifier = FakeCurrentProjectNotifier(
      initialProjectId: '950e8400-e29b-41d4-a716-446655440001',
    );

    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
      sentryWrapper: FakeSentryWrapper(),
    );

    Modular.init(
      _AppShellTestModule(
        authManager: authManager,
        authNotifier: authNotifier,
        currentProjectNotifier: fakeProjectNotifier,
        appBootstrap: appBootstrap,
      ),
    );
  });

  tearDown(() {
    Modular.destroy();
  });

  BuildContext? buildContext;

  Widget makeApp() {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        buildContext = context;
        return child!;
      },
      home: const AppShellPage(),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> tapTabByLabel(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Tab Navigation', () {
    testWidgets('switches tabs and renders tab pages', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(l10n().homeTab), findsAtLeastNWidgets(1));

      await tapTabByLabel(tester, l10n().calculationsTab);
      expect(find.text(l10n().calculationsTab), findsAtLeastNWidgets(1));

      await tapTabByLabel(tester, l10n().membersTab);
      expect(find.text(l10n().membersTab), findsAtLeastNWidgets(1));
    });

    testWidgets('bottom navigation bar is always visible', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CoreBottomNavBar), findsOneWidget);

      for (final tabLabel in [l10n().calculationsTab, l10n().membersTab]) {
        await tapTabByLabel(tester, tabLabel);
        expect(find.byType(CoreBottomNavBar), findsOneWidget);
      }
    });

    testWidgets('lazy loads tabs on first access', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tapTabByLabel(tester, l10n().costEstimation);

      expect(find.byType(CostEstimationLandingPage), findsOneWidget);
    });
  });

  group('App Bar', () {
    testWidgets('shows default app bar title', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(l10n().appTitle), findsAtLeastNWidgets(1));
    });
  });
}
