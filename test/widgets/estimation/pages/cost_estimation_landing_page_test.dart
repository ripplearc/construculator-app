import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
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

class _TestModule extends Module {
  final FakeAuthManager authManager;
  final FakeAuthNotifier authNotifier;
  final FakeAppRouter appRouter;

  _TestModule({
    required this.authManager,
    required this.authNotifier,
    required this.appRouter,
  });

  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthManager>(() => authManager);
    i.addLazySingleton<AuthNotifier>(() => authNotifier);
    i.addLazySingleton<AppRouter>(() => appRouter);
    i.add<AuthBloc>(
      () => AuthBloc(
        authManager: authManager,
        authNotifier: authNotifier,
        router: appRouter,
      ),
    );
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
      _TestModule(
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
    return const MaterialApp(home: CostEstimationLandingPage());
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

  User createUser({
    String id = 'user-1',
    String credentialId = 'test-id',
    String email = 'test@example.com',
    String firstName = 'John',
    String lastName = 'Doe',
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
    await tester.pump();

    expect(router.navigationHistory.isNotEmpty, isTrue);
    expect(router.navigationHistory.last.route, fullLoginRoute);
  });

  testWidgets('shows content when authenticated with user profile', (
    tester,
  ) async {
    final credential = createCredential();
    final user = createUser();

    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('My project'), findsOneWidget);
  });

  testWidgets('navigates to create account when user profile is null', (
    tester,
  ) async {
    const testEmail = 'test@example.com';
    final credential = createCredential(email: testEmail);

    authManager.setCurrentCredential(credential);
    authRepository.returnNullUserProfile = true;

    await tester.pumpWidget(makeApp());
    await tester.pump();

    expect(router.navigationHistory.isNotEmpty, isTrue);
    expect(router.navigationHistory.last.route, fullCreateAccountRoute);
    expect(router.navigationHistory.last.arguments, testEmail);
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

      expect(find.text('My project'), findsOneWidget);

      authNotifier.emitUserProfileChanged(null);
      await tester.pump();

      expect(router.navigationHistory.isNotEmpty, isTrue);
      expect(router.navigationHistory.last.route, fullCreateAccountRoute);
      expect(router.navigationHistory.last.arguments, testEmail);
    },
  );
}
