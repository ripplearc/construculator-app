import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/widgets/app_bottom_nav_bar.dart';
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
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

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

  _AppShellTestModule({
    required this.authManager,
    required this.authNotifier,
    required this.currentProjectNotifier,
  });

  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthManager>(() => authManager);
    i.addLazySingleton<AuthNotifier>(() => authNotifier);
    i.addLazySingleton<AppRouter>(FakeAppRouter.new);
    i.addLazySingleton<CurrentProjectNotifier>(() => currentProjectNotifier);
    i.addLazySingleton<ProjectUIProvider>(() => _FakeProjectUiProvider());
  }
}

void main() {
  late FakeCurrentProjectNotifier fakeProjectNotifier;

  setUp(() {
    final clock = FakeClockImpl();
    final authNotifier = FakeAuthNotifier();
    final authRepository = FakeAuthRepository(clock: clock);
    final authManager = FakeAuthManager(
      authNotifier: authNotifier,
      authRepository: authRepository,
      wrapper: FakeSupabaseWrapper(clock: clock),
      clock: clock,
    );
    fakeProjectNotifier = FakeCurrentProjectNotifier(
      initialProjectId: '950e8400-e29b-41d4-a716-446655440001',
    );

    Modular.init(
      _AppShellTestModule(
        authManager: authManager,
        authNotifier: authNotifier,
        currentProjectNotifier: fakeProjectNotifier,
      ),
    );
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeApp() {
    return MaterialApp(
      theme: createTestTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppShellPage(),
    );
  }

  group('Tab Navigation', () {
    testWidgets('switches tabs and renders tab pages', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Calculations'));
      await tester.pumpAndSettle();
      expect(find.text('Calculations'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();
      expect(find.text('Members'), findsAtLeastNWidgets(1));
    });

    testWidgets('bottom navigation bar is always visible', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNavBar), findsOneWidget);

      // Navigate to tabs that don't require extra bloc setup
      // Cost Estimation tab requires blocs from EstimationModule - tested separately
      for (final tabLabel in ['Calculations', 'Members']) {
        await tester.tap(find.text(tabLabel));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomNavBar), findsOneWidget);
      }
    });

    testWidgets('lazy loads tabs on first access', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // Initially only DashboardPage should be built
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(CalculationsPage), findsNothing);
      expect(find.byType(MembersPage), findsNothing);

      // After tapping Calculations, it should be loaded
      await tester.tap(find.text('Calculations'));
      await tester.pumpAndSettle();
      expect(find.byType(CalculationsPage), findsOneWidget);

      // Dashboard should still be in tree (offstage)
      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
    });
  });

  group('Tab State Preservation', () {
    testWidgets('tabs are only loaded on first access (lazy loading)', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // Step 1: Initially, only Dashboard (tab 0) is loaded
      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(CalculationsPage, skipOffstage: false), findsNothing);
      expect(find.byType(MembersPage, skipOffstage: false), findsNothing);

      // Step 2: Visit Calculations - it gets loaded
      await tester.tap(find.text('Calculations'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(CalculationsPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(MembersPage, skipOffstage: false), findsNothing);

      // Step 3: Visit Members - it gets loaded
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

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

      // Get the Dashboard element before switching
      final dashboardElementBefore = tester.element(find.byType(DashboardPage));

      // Switch to Calculations
      await tester.tap(find.text('Calculations'));
      await tester.pumpAndSettle();

      // Dashboard is offstage but still in tree
      expect(find.byType(DashboardPage), findsNothing); // Not visible
      expect(
        find.byType(DashboardPage, skipOffstage: false),
        findsOneWidget,
      ); // Still mounted

      // Get the Dashboard element after switching back
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      final dashboardElementAfter = tester.element(find.byType(DashboardPage));

      // Same Element instance = no rebuild occurred
      expect(dashboardElementAfter, same(dashboardElementBefore));
    });

    testWidgets('all visited tabs remain mounted when switching between them', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // Visit all tabs (except Cost Estimation which requires bloc setup)
      await tester.tap(find.text('Calculations'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      // Get Elements for all visited tabs
      final dashboardElement = tester.element(
        find.byType(DashboardPage, skipOffstage: false),
      );
      final calculationsElement = tester.element(
        find.byType(CalculationsPage, skipOffstage: false),
      );
      final membersElement = tester.element(
        find.byType(MembersPage, skipOffstage: false),
      );

      // Switch through tabs multiple times
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calculations'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      // Verify same Element instances (no rebuild)
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

      // Only visit Dashboard and Calculations, never Members
      await tester.tap(find.text('Calculations'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calculations'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Members should still not be loaded
      expect(find.byType(MembersPage, skipOffstage: false), findsNothing);

      // Dashboard and Calculations should be loaded
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

      await tester.tap(find.text('Cost Estimation'));
      await tester.pumpAndSettle();

      // Should show SizedBox.shrink() for the Cost Estimation tab
      // The bottom nav bar should still be visible
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('shows empty widget when projectId is empty string', (
      tester,
    ) async {
      fakeProjectNotifier.setCurrentProjectId('');

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cost Estimation'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });
  });

  group('App Bar', () {
    testWidgets('shows default app bar when projectId is null', (tester) async {
      fakeProjectNotifier.setCurrentProjectId(null);

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // Both AppShellPage and DashboardPage have AppBars showing "Construculator"
      expect(find.text('Construculator'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows project header app bar when projectId is set', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // The _FakeProjectUiProvider shows projectId in the AppBar title
      expect(find.text('950e8400-e29b-41d4-a716-446655440001'), findsOneWidget);
    });
  });

  group('Project subscription', () {
    testWidgets('updates UI when projectId changes', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // Initially shows project id
      expect(find.text('950e8400-e29b-41d4-a716-446655440001'), findsOneWidget);

      // Change project id
      fakeProjectNotifier.setCurrentProjectId('new-project-id');
      await tester.pumpAndSettle();

      // Should now show new project id
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

      // Both AppShellPage and DashboardPage have AppBars showing "Construculator"
      expect(find.text('Construculator'), findsAtLeastNWidgets(1));
    });
  });
}
