import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/shell_module.dart';
import 'package:construculator/features/app_header/presentation/widgets/title_search_app_bar.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/projects_bottom_sheet.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/analytics/domain/repositories/feature_flag_repository.dart';
import 'package:construculator/libraries/analytics/testing/fake_feature_flag_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_ui_provider.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/calculator_routes.dart';
import 'package:construculator/libraries/router/routes/project_search_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../utils/dashboard_shell_test_module.dart';
import '../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeCurrentProjectNotifier fakeProjectNotifier;
  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late AppBootstrap appBootstrap;

  setUpAll(() {
    CoreToast.disableTimers();
  });

  tearDownAll(() {
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeProjectNotifier = FakeCurrentProjectNotifier();
    final fakeClock = FakeClockImpl();
    fakeSupabaseWrapper = FakeSupabaseWrapper(clock: fakeClock);

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

    appBootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabaseWrapper,
      featureFlagRepository: FakeFeatureFlagRepository()
        ..flagOverrides['calculator-enabled'] = true,
    );

    Modular.init(ShellModule(appBootstrap));
    addTearDown(Modular.destroy);
    // Pre-bind DashboardModule so AuthNotifier, AuthManager, AppRouter, and
    // RecentEstimationsBloc are resolvable when AppShellPage is constructed.
    Modular.bindModule(DashboardModule(appBootstrap));

    Modular.replaceInstance<CurrentProjectNotifier>(fakeProjectNotifier);
    Modular.replaceInstance<ProjectUIProvider>(FakeProjectUIProvider());
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>.value(
            value: Modular.get<DashboardBloc>(),
          ),
          BlocProvider<AppShellBloc>.value(
            value: Modular.get<AppShellBloc>(),
          ),
          BlocProvider<ProjectDropdownBloc>.value(
            value: Modular.get<ProjectDropdownBloc>(),
          ),
          BlocProvider<RecentEstimationsBloc>.value(
            value: Modular.get<RecentEstimationsBloc>(),
          ),
        ],
        child: AppShellPage(
          projectUIProvider: Modular.get<ProjectUIProvider>(),
          currentProjectNotifier: Modular.get<CurrentProjectNotifier>(),
          router: Modular.get<AppRouter>(),
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

      expect(find.text(l10n().calculationsTab), findsAtLeastNWidgets(1));

      await tapTabByLabel(tester, l10n().estimatesTab);
      expect(find.text(l10n().estimatesTab), findsAtLeastNWidgets(1));
    });

    testWidgets('bottom navigation bar is always visible', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(CoreBottomNavBar), findsOneWidget);

      await tapTabByLabel(tester, l10n().estimatesTab);
      expect(find.byType(CoreBottomNavBar), findsOneWidget);
    });

    testWidgets('lazy loads tabs on first access', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(CalculationsPage), findsOneWidget);
      expect(find.byType(CostEstimationLandingPage), findsNothing);

      await tapTabByLabel(tester, l10n().estimatesTab);
      expect(find.byType(CostEstimationLandingPage), findsOneWidget);

      expect(find.byType(CalculationsPage, skipOffstage: false), findsOneWidget);
    });
  });

  group('Tab State Preservation', () {
    testWidgets('tabs are only loaded on first access (lazy loading)', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(CalculationsPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(CostEstimationLandingPage, skipOffstage: false), findsNothing);

      await tapTabByLabel(tester, l10n().estimatesTab);

      expect(find.byType(CalculationsPage, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(CostEstimationLandingPage, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('preserves tab widget tree when switching away (no rebuild)', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      final calculationsElementBefore = tester.element(find.byType(CalculationsPage));

      await tapTabByLabel(tester, l10n().estimatesTab);

      expect(find.byType(CalculationsPage), findsNothing);
      expect(find.byType(CalculationsPage, skipOffstage: false), findsOneWidget);

      await tapTabByLabel(tester, l10n().calculationsTab);

      final calculationsElementAfter = tester.element(find.byType(CalculationsPage));

      expect(calculationsElementAfter, same(calculationsElementBefore));
    });

    testWidgets('all visited tabs remain mounted when switching between them', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tapTabByLabel(tester, l10n().estimatesTab);

      final calculationsElement = tester.element(
        find.byType(CalculationsPage, skipOffstage: false),
      );
      final estimatesElement = tester.element(
        find.byType(CostEstimationLandingPage, skipOffstage: false),
      );

      await tapTabByLabel(tester, l10n().calculationsTab);
      await tapTabByLabel(tester, l10n().estimatesTab);

      expect(
        tester.element(find.byType(CalculationsPage, skipOffstage: false)),
        same(calculationsElement),
      );
      expect(
        tester.element(find.byType(CostEstimationLandingPage, skipOffstage: false)),
        same(estimatesElement),
      );
    });

    testWidgets('estimates tab remains unloaded until first access', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(CostEstimationLandingPage, skipOffstage: false), findsNothing);
      expect(find.byType(CalculationsPage, skipOffstage: false), findsOneWidget);
    });
  });

  group('Estimates Tab', () {
    testWidgets(
      'shows CostEstimationLandingPage when estimates tab is tapped',
      (tester) async {
        await tester.pumpWidget(makeApp());
        await tester.pumpAndSettle();

        await tapTabByLabel(tester, l10n().estimatesTab);

        expect(find.byType(CostEstimationLandingPage), findsOneWidget);
      },
    );
  });

  group('App Bar', () {
    testWidgets('renders TitleSearchAppBar on calculations tab when no project is selected', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pump();

      expect(find.byType(TitleSearchAppBar), findsOneWidget);
    });
  });

  group('Calculator action button', () {
    testWidgets(
        'tapping the trailing button pushes the calculator route when '
        'calculator-enabled is true', (tester) async {
      final fakeRouter = FakeAppRouter();
      Modular.replaceInstance<AppRouter>(fakeRouter);

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      final trailingIcon = find.byType(CoreIconWidget).last;
      await tester.tap(trailingIcon);
      await tester.pump();

      expect(
        fakeRouter.navigationHistory,
        contains(const RouteCall(calculatorBaseRoute, null)),
      );
    });

    testWidgets(
        'tapping the trailing button does nothing when calculator-enabled '
        'is false', (tester) async {
      final fakeRouter = FakeAppRouter();
      Modular.replaceInstance<AppRouter>(fakeRouter);
      Modular.replaceInstance<FeatureFlagRepository>(
        FakeFeatureFlagRepository(),
      );

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      final trailingIcon = find.byType(CoreIconWidget).last;
      await tester.tap(trailingIcon);
      await tester.pump();

      expect(fakeRouter.navigationHistory, isEmpty);
    });
  });

  group('Project Search Entry', () {
    // The sheet's full content needs more height than the default 800x600
    // test view; width stays at 800 so the dashboard behind the sheet lays
    // out as in the other tests.
    void useTallSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets(
      'tapping the header project selector opens the projects bottom sheet',
      (tester) async {
        useTallSurface(tester);
        await tester.pumpWidget(makeApp());
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('title_search_app_bar_project_selector')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProjectsBottomSheet), findsOneWidget);
        expect(find.text(l10n().projectsSheetTitle), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the sheet search field dismisses the sheet and navigates to '
      'project search',
      (tester) async {
        final fakeRouter = FakeAppRouter();
        Modular.replaceInstance<AppRouter>(fakeRouter);

        useTallSurface(tester);
        await tester.pumpWidget(makeApp());
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('title_search_app_bar_project_selector')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('projects_search_field')));
        await tester.pumpAndSettle();

        expect(find.byType(ProjectsBottomSheet), findsNothing);
        expect(fakeRouter.navigationHistory, hasLength(1));
        expect(fakeRouter.navigationHistory.single.route, projectSearchRoute);
      },
    );
  });

  group('Project Selection Wiring', () {
    late FakeProjectRepository fakeProjectRepository;

    Project buildProject(String id, String name, DateTime updatedAt) {
      return Project(
        id: id,
        projectName: name,
        creatorUserId: 'fake-id',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: updatedAt,
        status: ProjectStatus.active,
      );
    }

    setUp(() {
      Modular.destroy();
      Modular.init(DashboardShellTestModule(appBootstrap));
      final supabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      supabase.setCurrentUser(
        FakeUser(
          id: 'fake-id',
          email: 'test@example.com',
          createdAt: '2025-01-01T00:00:00Z',
        ),
      );
      fakeProjectRepository = FakeProjectRepository();
      Modular.replaceInstance<ProjectRepository>(fakeProjectRepository);
      Modular.replaceInstance<CurrentProjectNotifier>(fakeProjectNotifier);
      Modular.replaceInstance<CostEstimationRepository>(
        FakeCostEstimationRepository(),
      );
      Modular.replaceInstance<ProjectUIProvider>(FakeProjectUIProvider());
    });

    tearDown(() => fakeProjectNotifier.reset());

    testWidgets(
      'starts the projects watch on shell mount and auto-selects the first '
      'project without any manual dispatch',
      (tester) async {
        fakeProjectRepository.setAccessibleProjects([
          buildProject('project-a', 'Project A', DateTime(2025, 1, 2)),
        ]);

        final dropdownBloc = Modular.get<ProjectDropdownBloc>();
        final loaded = dropdownBloc.stream.firstWhere(
          (s) => s is ProjectDropdownLoadSuccess && s.selectedProject != null,
        );

        // No ProjectDropdownStarted is dispatched here: mounting the shell
        // must start the watch itself (CA-900 — previously nothing did
        // until the projects sheet was opened, so no project auto-selected
        // on login).
        await tester.pumpWidget(makeApp());
        await tester.pump();
        await tester.pump();

        await tester.runAsync(() => loaded);
        await tester.pump();
        expect(fakeProjectNotifier.currentProjectId, 'project-a');
      },
    );

    testWidgets(
      'updates CurrentProjectNotifier when project selection changes',
      (tester) async {
        fakeProjectRepository.setAccessibleProjects([
          buildProject('project-a', 'Project A', DateTime(2025, 1, 2)),
          buildProject('project-b', 'Project B', DateTime(2025, 1, 1)),
        ]);

        // Subscribe before pumping: mounting the shell auto-dispatches
        // ProjectDropdownStarted from initState, so a manual dispatch here
        // would restart the already-running watch.
        final dropdownBloc = Modular.get<ProjectDropdownBloc>();
        final firstLoad = dropdownBloc.stream
            .firstWhere((s) => s is ProjectDropdownLoadSuccess);

        await tester.pumpWidget(makeApp());
        // Two pumps: first drains AppShellInitialized, second drains the
        // resulting tab-load rebuild. pumpAndSettle is avoided because
        // DashboardShellTestModule keeps animations running indefinitely.
        await tester.pump();
        await tester.pump();

        await tester.runAsync(() => firstLoad);
        await tester.pump();
        expect(fakeProjectNotifier.currentProjectId, 'project-a');

        final secondLoad = dropdownBloc.stream.firstWhere(
          (s) =>
              s is ProjectDropdownLoadSuccess &&
              s.selectedProject!.id == 'project-b',
        );
        dropdownBloc.add(const ProjectDropdownSelected('project-b'));
        await tester.runAsync(() => secondLoad);
        await tester.pump();
        expect(fakeProjectNotifier.currentProjectId, 'project-b');
      },
    );
  });
}
