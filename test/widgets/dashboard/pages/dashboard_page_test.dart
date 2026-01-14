import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class _DashboardPageTestModule extends Module {
  final FakeAuthManager authManager;
  final FakeAuthNotifier authNotifier;
  final FakeAppRouter appRouter;

  _DashboardPageTestModule({
    required this.authManager,
    required this.authNotifier,
    required this.appRouter,
  });

  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthManager>(() => authManager);
    i.addLazySingleton<AuthNotifier>(() => authNotifier);
    i.addLazySingleton<AppRouter>(() => appRouter);
  }
}

void main() {
  late FakeClockImpl clock;
  late FakeAuthRepository authRepository;
  late FakeAuthManager authManager;
  late FakeAuthNotifier authNotifier;
  late FakeAppRouter router;

  setUp(() {
    clock = FakeClockImpl();
    authNotifier = FakeAuthNotifier();
    authRepository = FakeAuthRepository(clock: clock);
    authManager = FakeAuthManager(
      authNotifier: authNotifier,
      authRepository: authRepository,
      wrapper: FakeSupabaseWrapper(clock: clock),
      clock: clock,
    );
    router = FakeAppRouter();

    Modular.init(
      _DashboardPageTestModule(
        authManager: authManager,
        authNotifier: authNotifier,
        appRouter: router,
      ),
    );
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeApp() {
    return MaterialApp(
      theme: CoreTheme.light(),
      home: const DashboardPage(),
    );
  }

  UserCredential createCredential({
    String id = 'test-id',
    String email = 'test@example.com',
  }) {
    return UserCredential(
      id: id,
      email: email,
      metadata: {},
      createdAt: clock.now(),
    );
  }

  const String firstName = 'John';
  const String lastName = 'Doe';

  User createUser({
    String id = 'user-1',
    String credentialId = 'test-id',
    String email = 'test@example.com',
    String firstName = firstName,
    String lastName = lastName,
  }) {
    return User(
      id: id,
      credentialId: credentialId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      professionalRole: 'Engineer',
      createdAt: clock.now(),
      updatedAt: clock.now(),
      userStatus: UserProfileStatus.active,
      userPreferences: {},
    );
  }

  testWidgets('navigates to login when credentials id is null', (tester) async {
    await tester.pumpWidget(makeApp());

    expect(router.navigationHistory.length, 1);
    expect(router.navigationHistory.first.route, fullLoginRoute);
  });

  testWidgets('renders welcome text with user full name', (tester) async {
    final credential = createCredential();
    final user = createUser();

    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, $firstName $lastName!'), findsOneWidget);
    expect(find.text('You are now logged in to your account'), findsOneWidget);
  });

  testWidgets('logout navigates to login', (tester) async {
    final credential = createCredential();
    final user = createUser();

    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CoreButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(router.navigationHistory.isNotEmpty, isTrue);
    expect(router.navigationHistory.last.route, fullLoginRoute);
  });

  testWidgets('navigates to create account when user profile event is null', (
    tester,
  ) async {
    const testEmail = 'test@example.com';
    final credential = createCredential(email: testEmail);

    authManager.setCurrentCredential(credential);
    authRepository.returnNullUserProfile = true;

    await tester.pumpWidget(makeApp());
    await tester.pump();

    expect(router.navigationHistory.length, 1);
    expect(router.navigationHistory.first.route, fullCreateAccountRoute);
    expect(router.navigationHistory.first.arguments, testEmail);
  });

  testWidgets('shows placeholder when getUserProfile returns null', (
    tester,
  ) async {
    final credential = createCredential();

    authManager.setCurrentCredential(credential);
    authRepository.returnNullUserProfile = true;

    await tester.pumpWidget(makeApp());
    await tester.pump();

    expect(find.text('Welcome back, ...'), findsOneWidget);
  });

  testWidgets(
    'navigates to create account when user profile stream emits null',
    (tester) async {
      const testEmail = 'stream-test@example.com';
      final credential = createCredential(email: testEmail);
      final user = createUser(email: testEmail);

      authManager.setCurrentCredential(credential);
      authRepository.setUserProfile(user);

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome back, $firstName $lastName!'), findsOneWidget);

      authNotifier.emitUserProfileChanged(null);
      await tester.pumpAndSettle();

      expect(router.navigationHistory.length, 1);
      expect(router.navigationHistory.first.route, fullCreateAccountRoute);
      expect(router.navigationHistory.first.arguments, testEmail);
    },
  );
}
