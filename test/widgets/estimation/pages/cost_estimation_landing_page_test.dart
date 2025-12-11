import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
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

class _CostEstimationLandingPageTestModule extends Module {
  final AppBootstrap appBootstrap;
  _CostEstimationLandingPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    EstimationModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  late Clock clock;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();

    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_CostEstimationLandingPageTestModule(appBootstrap));

    clock = Modular.get<Clock>();
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
    Modular.replaceInstance<AuthBloc>(
      AuthBloc(
        authManager: Modular.get(),
        authNotifier: Modular.get(),
        router: router,
      ),
    );
  });

  Widget makeApp() {
    return const MaterialApp(home: CostEstimationLandingPage());
  }

  void setUpAuthenticatedUser({
    required String credentialId,
    required String email,
    String userId = 'user-1',
    String? profilePhotoUrl,
  }) {
    // Set up authenticated user
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: credentialId,
        email: email,
        createdAt: clock.now().toIso8601String(),
      ),
    );

    // Set up user profile in users table
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

  testWidgets('navigates to login when credentials id is null', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pump();

    expect(router.navigationHistory.isNotEmpty, isTrue);
    expect(router.navigationHistory.last.route, fullLoginRoute);
  });

  testWidgets('shows content when authenticated with user profile', (
    tester,
  ) async {
    setUpAuthenticatedUser(
      credentialId: 'test-credential-id',
      email: 'test@example.com',
    );

    await tester.pumpWidget(makeApp());

    await tester.pump();

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

      await tester.pumpWidget(makeApp());

      await tester.pump();

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });

      await tester.pump();

      final projectHeaderAppBar = tester.widget<ProjectHeaderAppBar>(
        find.byType(ProjectHeaderAppBar),
      );

      expect(projectHeaderAppBar.projectId, 'My project');
      expect(projectHeaderAppBar.avatarImage, isNotNull);
      expect(projectHeaderAppBar.avatarImage, isA<NetworkImage>());
      expect((projectHeaderAppBar.avatarImage! as NetworkImage).url, avatarUrl);
    },
  );
}
