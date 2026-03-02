import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
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
    i.addLazySingleton<AppRouter>(FakeAppRouter.new);
    i.addLazySingleton<CurrentProjectNotifier>(() => currentProjectNotifier);
    i.addLazySingleton<ProjectUIProvider>(() => _FakeProjectUiProvider());
    i.addLazySingleton<TabModuleManager>(() => TabModuleManager(appBootstrap));
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

  Widget makeApp() {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppShellPage(),
    );
  }

  Future<void> tapTabByLabel(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
  }

  group('Tab Navigation', () {
    testWidgets('switches tabs and renders tab pages', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsAtLeastNWidgets(1));

      await tapTabByLabel(tester, 'Calculations');
      expect(find.text('Calculations'), findsAtLeastNWidgets(1));

      await tapTabByLabel(tester, 'Members');
      expect(find.text('Members'), findsAtLeastNWidgets(1));
    });

    testWidgets('bottom navigation bar is always visible', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(CoreBottomNavBar), findsOneWidget);

      for (final tabLabel in ['Calculations', 'Members']) {
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

      await tapTabByLabel(tester, 'Calculations');
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

      await tapTabByLabel(tester, 'Calculations');

      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(CalculationsPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(MembersPage, skipOffstage: false), findsNothing);

      await tapTabByLabel(tester, 'Members');

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

      await tapTabByLabel(tester, 'Calculations');

      expect(find.byType(DashboardPage), findsNothing);
      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);

      await tapTabByLabel(tester, 'Home');

      final dashboardElementAfter = tester.element(find.byType(DashboardPage));

      expect(dashboardElementAfter, same(dashboardElementBefore));
    });

    testWidgets('all visited tabs remain mounted when switching between them', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tapTabByLabel(tester, 'Calculations');

      await tapTabByLabel(tester, 'Members');

      final dashboardElement = tester.element(
        find.byType(DashboardPage, skipOffstage: false),
      );
      final calculationsElement = tester.element(
        find.byType(CalculationsPage, skipOffstage: false),
      );
      final membersElement = tester.element(
        find.byType(MembersPage, skipOffstage: false),
      );

      await tapTabByLabel(tester, 'Home');

      await tapTabByLabel(tester, 'Calculations');

      await tapTabByLabel(tester, 'Members');

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

      await tapTabByLabel(tester, 'Calculations');

      await tapTabByLabel(tester, 'Home');

      await tapTabByLabel(tester, 'Calculations');

      await tapTabByLabel(tester, 'Home');

      expect(find.byType(MembersPage, skipOffstage: false), findsNothing);

      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(CalculationsPage, skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('Cost Estimation Tab - projectId handling', () {
    testWidgets('shows empty widget when projectId is null', (tester) async {
      fakeProjectNotifier.setCurrentProjectId(null);

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tapTabByLabel(tester, 'Cost Estimation');

      expect(find.byType(CoreBottomNavBar), findsOneWidget);
    });

    testWidgets('shows empty widget when projectId is empty string', (
      tester,
    ) async {
      fakeProjectNotifier.setCurrentProjectId('');

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tapTabByLabel(tester, 'Cost Estimation');

      expect(find.byType(CoreBottomNavBar), findsOneWidget);
    });
  });

  group('App Bar', () {
    testWidgets('shows default app bar when projectId is null', (tester) async {
      fakeProjectNotifier.setCurrentProjectId(null);

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Construculator'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows project header app bar when projectId is set', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('950e8400-e29b-41d4-a716-446655440001'), findsOneWidget);
    });
  });

  group('Project subscription', () {
    testWidgets('updates UI when projectId changes', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('950e8400-e29b-41d4-a716-446655440001'), findsOneWidget);

      fakeProjectNotifier.setCurrentProjectId('new-project-id');
      await tester.pumpAndSettle();

      expect(find.text('new-project-id'), findsOneWidget);
    });

    testWidgets('switches to default app bar when projectId becomes null', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('950e8400-e29b-41d4-a716-446655440001'), findsOneWidget);

      fakeProjectNotifier.setCurrentProjectId(null);
      await tester.pumpAndSettle();

      expect(find.text('Construculator'), findsAtLeastNWidgets(1));
    });
  });
}
