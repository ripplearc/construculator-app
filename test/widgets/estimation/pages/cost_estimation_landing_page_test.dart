import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
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
    r.module('/estimation', module: EstimationModule(appBootstrap));
  }
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late AppBootstrap appBootstrap;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();

    appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );

    clock = FakeClockImpl();
  });
  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  Widget makeApp() {
    return ModularApp(
      module: _CostEstimationLandingPageTestModule(appBootstrap),
      child: MaterialApp.router(routerConfig: Modular.routerConfig),
    );
  }

  Future<void> pumpAppAtRoute(WidgetTester tester, String route) async {
    Modular.setInitialRoute(route);
    await tester.pumpWidget(makeApp());
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

  testWidgets('shows content when authenticated with user profile', (
    tester,
  ) async {
    setUpAuthenticatedUser(
      credentialId: 'test-credential-id',
      email: 'test@example.com',
    );

    await pumpAppAtRoute(tester, fullEstimationLandingRoute);

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

      await pumpAppAtRoute(tester, fullEstimationLandingRoute);

      final projectHeaderAppBar = tester.widget<ProjectHeaderAppBar>(
        find.byType(ProjectHeaderAppBar),
      );

      expect(projectHeaderAppBar.projectId, '');
      expect(projectHeaderAppBar.avatarImage, isNotNull);
      expect(projectHeaderAppBar.avatarImage, isA<NetworkImage>());
      expect((projectHeaderAppBar.avatarImage! as NetworkImage).url, avatarUrl);
    },
  );
}
