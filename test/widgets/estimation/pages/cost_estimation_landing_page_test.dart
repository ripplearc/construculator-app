import 'dart:async';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_widget.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
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

import '../../../units/features/estimation/helpers/estimation_test_data_map_factory.dart';
import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet.dart';

class _CostEstimationLandingPageTestModule extends Module {
  final AppBootstrap appBootstrap;

  _CostEstimationLandingPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    ProjectModule(appBootstrap),
    AuthLibraryModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    i.add<AuthBloc>(
      () => AuthBloc(authManager: i(), authNotifier: i(), router: i()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.module(estimationBaseRoute, module: EstimationModule(appBootstrap));
  }
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late AppBootstrap appBootstrap;
  late FakeAppRouter fakeAppRouter;

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
    Modular.init(_CostEstimationLandingPageTestModule(appBootstrap));
    fakeAppRouter = Modular.get<AppRouter>() as FakeAppRouter;
    Modular.setInitialRoute(testEstimationRoute);
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
    fakeAppRouter.reset();
  });

  Widget makeApp() {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      theme: CoreTheme.light(),
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

  void addMultipleCostEstimations(List<Map<String, dynamic>> estimations) {
    fakeSupabase.addTableData('cost_estimates', estimations);
  }

  group('Auth and header', () {
    testWidgets('shows content when authenticated with user profile', (
      tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      // TODO: https://ripplearc.youtrack.cloud/issue/CA-162/Dashboard-Create-Project-Repository correct this to an actual name from fake project table
      expect(find.text('Sample Construction Project'), findsOneWidget);
    });

    testWidgets(
      'passes project id and avatar image to ProjectHeaderAppBar when user has photo',
      (tester) async {
        const avatarUrl = 'https://example.com/avatar.jpg';

        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          profilePhotoUrl: avatarUrl,
        );

        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exception is NetworkImageLoadException) return;
          originalOnError!.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        await pumpAppAtRoute(tester, testEstimationRoute);

        final projectHeaderAppBar = tester.widget<ProjectHeaderAppBar>(
          find.byType(ProjectHeaderAppBar),
        );

        expect(projectHeaderAppBar.projectId, testProjectId);
        expect(projectHeaderAppBar.avatarImage, isNotNull);
        expect(projectHeaderAppBar.avatarImage, isA<NetworkImage>());
        expect(
          (projectHeaderAppBar.avatarImage! as NetworkImage).url,
          avatarUrl,
        );
      },
    );
  });

  group('Add Estimation Button', () {
    testWidgets(
      'renders as CoreButton with expected label when cost estimation landing page is loaded',
      (tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        await pumpAppAtRoute(tester, testEstimationRoute);

        final addButton = find.byType(CoreButton);
        expect(addButton, findsOneWidget);
        expect(find.text(l10n().addEstimation), findsOneWidget);
      },
    );

    testWidgets('is visible when estimations list has data', (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Test Estimation',
        ),
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byType(CoreButton), findsOneWidget);
      expect(find.text(l10n().addEstimation), findsOneWidget);
    });

    testWidgets(
      'shows trailing loading indicator and disables add button while creating',
      (tester) async {
        setUpAuthenticatedUser(
          credentialId: 'test-credential-id',
          email: 'test@example.com',
        );

        addCostEstimationData(
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: 'estimation-1',
            projectId: testProjectId,
            estimateName: 'Existing Estimation',
          ),
        );

        await pumpAppAtRoute(tester, testEstimationRoute);
        await tester.pumpAndSettle();

        expect(find.byType(CostEstimationTile), findsOneWidget);

        fakeSupabase.shouldDelayOperations = true;
        fakeSupabase.completer = Completer();

        await tester.tap(find.text(l10n().addEstimation));
        await tester.pump();

        final addButton = tester.widget<CoreButton>(
          find.widgetWithText(CoreButton, l10n().addEstimation),
        );
        expect(addButton.isDisabled, isTrue);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        fakeSupabase.completer?.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('appends new estimation tile after successful creation', (
      tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Existing Estimation',
        ),
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byType(CostEstimationTile), findsOneWidget);

      await tester.tap(find.text(l10n().addEstimation));
      await tester.pumpAndSettle();

      expect(find.byType(CostEstimationTile), findsNWidgets(2));
      expect(find.text(l10n().untitledEstimation), findsOneWidget);
    });

    testWidgets('shows error toast when creation fails', (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Existing Estimation',
        ),
      );

      fakeSupabase.shouldThrowOnInsert = true;
      fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;

      await pumpAppAtRoute(tester, testEstimationRoute);

      await tester.tap(find.text(l10n().addEstimation));
      await tester.pumpAndSettle();

      expect(find.text(l10n().connectionError), findsOneWidget);

      final addButton = tester.widget<CoreButton>(
        find.widgetWithText(CoreButton, l10n().addEstimation),
      );
      expect(addButton.isDisabled, isFalse);
      expect(find.byType(CostEstimationTile), findsOneWidget);
    });
  });

  group('Cost Estimation Bloc Integration', () {
    testWidgets('shows empty page when no estimations exist', (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      final locale = l10n();

      expect(find.byType(CostEstimationEmptyWidget), findsOneWidget);
      expect(find.text(locale.costEstimationEmptyMessage), findsOneWidget);
      expect(find.byType(CostEstimationTile), findsNothing);
    });

    testWidgets('shows list of estimations when data exists', (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addMultipleCostEstimations([
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Kitchen Remodel',
          totalCost: 25000.0,
        ),
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-2',
          projectId: testProjectId,
          estimateName: 'Bathroom Renovation',
          totalCost: 15000.0,
        ),
      ]);

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.byType(CostEstimationTile), findsNWidgets(2));
      expect(find.byType(CostEstimationEmptyWidget), findsNothing);
      expect(find.text('Kitchen Remodel'), findsOneWidget);
      expect(find.text('Bathroom Renovation'), findsOneWidget);
    });

    testWidgets('navigates to details page when tile is tapped', (
      tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      const estimationId = 'estimation-1';
      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: estimationId,
          projectId: testProjectId,
          estimateName: 'Kitchen Remodel',
          totalCost: 25000.0,
        ),
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      await tester.tap(find.text('Kitchen Remodel'));
      await tester.pumpAndSettle();

      final navigatedRoute = fakeAppRouter.navigationHistory.last;
      expect(
        navigatedRoute.route,
        equals('$fullEstimationDetailsRoute/$estimationId'),
      );
    });

    testWidgets('shows timeout error message when timeout error occurs', (
      tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      fakeSupabase.shouldThrowOnSelectMultiple = true;
      fakeSupabase.selectMultipleExceptionType = SupabaseExceptionType.timeout;

      await pumpAppAtRoute(tester, testEstimationRoute);

      final locale = l10n();

      expect(find.text(locale.timeoutError), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets('shows connection error message when connection error occurs', (
      tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      fakeSupabase.shouldThrowOnSelectMultiple = true;
      fakeSupabase.selectMultipleExceptionType = SupabaseExceptionType.socket;

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.text(l10n().connectionError), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets('shows unexpected error message when unexpected error occurs', (
      tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      fakeSupabase.shouldThrowOnSelectMultiple = true;
      fakeSupabase.selectMultipleExceptionType = SupabaseExceptionType.type;

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.text(l10n().unexpectedErrorMessage), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets('refreshes estimations when pull to refresh', (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Initial Estimation',
        ),
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      expect(find.text('Initial Estimation'), findsOneWidget);

      fakeSupabase.clearTableData('cost_estimates');
      addMultipleCostEstimations([
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: 'Initial Estimation',
        ),
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-2',
          projectId: testProjectId,
          estimateName: 'Updated Estimation',
        ),
      ]);

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.text('Initial Estimation'), findsOneWidget);
      expect(find.text('Updated Estimation'), findsOneWidget);
      expect(find.byType(CostEstimationTile), findsNWidgets(2));
    });
  });

  group('Estimation Actions Sheet', () {
    testWidgets('shows actions sheet when menu icon is tapped', (tester) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      const estimationName = 'Kitchen Remodel';
      addCostEstimationData(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: estimationName,
        ),
      );

      await pumpAppAtRoute(tester, testEstimationRoute);

      await tester.tap(find.byKey(const Key('menuIcon')));
      await tester.pumpAndSettle();

      expect(find.byType(EstimationActionsSheet), findsOneWidget);
    });

    testWidgets('calls router.pop when rename action is tapped', (
      tester,
    ) async {
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

      await pumpAppAtRoute(tester, testEstimationRoute);

      await tester.tap(find.byKey(const Key('menuIcon')));
      await tester.pumpAndSettle();

      expect(fakeAppRouter.popCalls, 0);

      await tester.tap(find.text(l10n().renameAction));
      await tester.pumpAndSettle();

      expect(fakeAppRouter.popCalls, 1);
    });

    testWidgets('calls router.pop when favourite action is tapped', (
      tester,
    ) async {
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

      await pumpAppAtRoute(tester, testEstimationRoute);

      await tester.tap(find.byKey(const Key('menuIcon')));
      await tester.pumpAndSettle();

      expect(fakeAppRouter.popCalls, 0);

      await tester.tap(find.text(l10n().favouriteAction));
      await tester.pumpAndSettle();

      expect(fakeAppRouter.popCalls, 1);
    });

    testWidgets('calls router.pop when remove action is tapped', (
      tester,
    ) async {
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

      await pumpAppAtRoute(tester, testEstimationRoute);

      await tester.tap(find.byKey(const Key('menuIcon')));
      await tester.pumpAndSettle();

      expect(fakeAppRouter.popCalls, 0);

      await tester.tap(find.text(l10n().removeAction));
      await tester.pumpAndSettle();

      expect(fakeAppRouter.popCalls, 1);
    });
  });

  group('Route validation', () {
    testWidgets('renders empty screen when projectId is missing', (
      tester,
    ) async {
      setUpAuthenticatedUser(
        credentialId: 'test-credential-id',
        email: 'test@example.com',
      );

      await pumpAppAtRoute(tester, '$fullEstimationLandingRoute/');

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(CostEstimationEmptyWidget), findsNothing);
    });
  });
}
