import 'package:construculator/features/auth/testing/auth_test_module.dart';
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
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  late Clock clock;

  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
    clock = Modular.get<Clock>();
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeApp(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders welcome text with user full name and logs out', (
    tester,
  ) async {
    final nowIso = clock.now().toIso8601String();
    const credentialId = 'cred-1';
    const email = 'john.doe@example.com';
    const firstName = 'John';
    const lastName = 'Doe';
    fakeSupabase.setCurrentUser(
      FakeUser(id: credentialId, email: email, createdAt: nowIso),
    );
    fakeSupabase.addTableData('users', [
      {
        'id': '1',
        'credential_id': credentialId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'professional_role': 'Engineer',
        'created_at': nowIso,
        'updated_at': nowIso,
        'user_status': 'active',
        'user_preferences': <String, dynamic>{},
      },
    ]);

    await tester.pumpWidget(makeApp(const DashboardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, $firstName $lastName!'), findsOneWidget);
    expect(find.text('You are now logged in to your account'), findsOneWidget);

    await tester.tap(find.widgetWithText(CoreButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(router.navigationHistory.isNotEmpty, isTrue);
    expect(router.navigationHistory.first.route, fullLoginRoute);
  });

  group('initState behavior - covering highlighted functionality', () {
    late FakeAuthManager fakeAuthManager;
    late FakeAuthNotifier fakeAuthNotifier;
    late FakeAppRouter fakeRouter;
    late FakeClockImpl fakeClock;
    late FakeAuthRepository fakeAuthRepository;

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeAuthRepository = FakeAuthRepository(clock: fakeClock);
      fakeAuthManager = FakeAuthManager(
        authNotifier: FakeAuthNotifier(),
        authRepository: fakeAuthRepository,
        wrapper: FakeSupabaseWrapper(clock: fakeClock),
        clock: fakeClock,
      );
      fakeAuthNotifier = FakeAuthNotifier();
      fakeRouter = FakeAppRouter();

      Modular.bindModule(
        TestModule(
          authManager: fakeAuthManager,
          authNotifier: fakeAuthNotifier,
          appRouter: fakeRouter,
        ),
      );
    });

    tearDown(() {
      Modular.destroy();
    });

    testWidgets(
      'should navigate to create account when user profile event is null',
      (WidgetTester tester) async {
        final testEmail = 'test@example.com';
        final testCredential = UserCredential(
          id: 'test-id',
          email: testEmail,
          metadata: {},
          createdAt: fakeClock.now(),
        );
        fakeAuthManager.setCurrentCredential(testCredential);

        await tester.pumpWidget(MaterialApp(home: const DashboardPage()));
        fakeAuthNotifier.emitUserProfileChanged(null);
        await tester.pump();

        expect(fakeRouter.navigationHistory.length, 1);
        expect(
          fakeRouter.navigationHistory.first.route,
          fullCreateAccountRoute,
        );
        expect(fakeRouter.navigationHistory.first.arguments, testEmail);
      },
    );

    testWidgets('should navigate to login when user credentials id is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const DashboardPage()));

      expect(fakeRouter.navigationHistory.length, 1);
      expect(fakeRouter.navigationHistory.first.route, fullLoginRoute);
    });

    testWidgets('should load user profile when credentials id is not null', (
      WidgetTester tester,
    ) async {
      final testUserId = 'test-user-id';
      final testCredential = UserCredential(
        id: testUserId,
        email: 'test@example.com',
        metadata: {},
        createdAt: fakeClock.now(),
      );

      final testUser = User(
        id: testUserId,
        credentialId: testUserId,
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        professionalRole: 'Engineer',
        createdAt: fakeClock.now(),
        updatedAt: fakeClock.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      );

      fakeAuthManager.setCurrentCredential(testCredential);
      fakeAuthRepository.setUserProfile(testUser);
      fakeAuthNotifier.emitUserProfileChanged(null);

      await tester.pumpWidget(MaterialApp(home: const DashboardPage()));
      await tester.pump();

      expect(fakeAuthRepository.getUserProfileCalls.length, 1);
      expect(fakeAuthRepository.getUserProfileCalls.first, testUserId);

      expect(find.text('Welcome back, John Doe!'), findsOneWidget);
    });

    testWidgets('should handle getUserProfile error with mounted check', (
      WidgetTester tester,
    ) async {
      final testUserId = 'test-user-id';
      final testCredential = UserCredential(
        id: testUserId,
        email: 'test@example.com',
        metadata: {},
        createdAt: fakeClock.now(),
      );

      fakeAuthManager.setCurrentCredential(testCredential);
      fakeAuthRepository.returnNullUserProfile = true;
      fakeAuthNotifier.emitUserProfileChanged(null);

      await tester.pumpWidget(MaterialApp(home: const DashboardPage()));
      await tester.pump();

      expect(fakeAuthRepository.getUserProfileCalls.length, 1);
      expect(fakeAuthRepository.getUserProfileCalls.first, testUserId);

      expect(find.text('Welcome back, ...'), findsOneWidget);
    });
  });
}

class TestModule extends Module {
  final FakeAuthManager authManager;
  final FakeAuthNotifier authNotifier;
  final FakeAppRouter appRouter;

  TestModule({
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
