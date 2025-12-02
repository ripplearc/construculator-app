import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late FakeAuthManager fakeAuthManager;
  late FakeAuthRepository fakeAuthRepository;
  late FakeAppRouter router;
  late Clock clock;

  setUp(() {
    CoreToast.disableTimers();

    Modular.init(AuthTestModule());
    router = Modular.get<AppRouter>() as FakeAppRouter;
    clock = Modular.get<Clock>();

    fakeAuthRepository = Modular.get<AuthRepository>() as FakeAuthRepository;

    fakeAuthManager = FakeAuthManager(
      authNotifier: Modular.get<AuthNotifierController>(),
      authRepository: fakeAuthRepository,
      wrapper: Modular.get<SupabaseWrapper>(),
      clock: clock,
    );
    Modular.replaceInstance<AuthManager>(fakeAuthManager);

    Modular.replaceInstance<AuthBloc>(
      AuthBloc(
        authManager: fakeAuthManager,
        authNotifier: Modular.get<AuthNotifier>(),
        router: router,
      ),
    );
  });

  tearDown(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  Widget makeApp() {
    return const MaterialApp(home: CostEstimationLandingPage());
  }

  User createUser({
    String id = 'user-1',
    required String credentialId,
    String email = 'test@example.com',
    String firstName = 'John',
    String lastName = 'Doe',
    String? profilePhotoUrl,
  }) {
    return User(
      id: id,
      credentialId: credentialId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      professionalRole: 'Engineer',
      profilePhotoUrl: profilePhotoUrl,
      createdAt: clock.now(),
      updatedAt: clock.now(),
      userStatus: UserProfileStatus.active,
      userPreferences: const {},
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
    const testEmail = 'test@example.com';
    const credentialId = 'test-credential-id';

    fakeAuthManager.setCurrentCredential(
      UserCredential(
        id: credentialId,
        email: testEmail,
        metadata: {},
        createdAt: clock.now(),
      ),
    );

    // Set up user profile
    fakeAuthRepository.setUserProfile(
      createUser(credentialId: credentialId, email: testEmail),
    );

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('My project'), findsOneWidget);
  });

  testWidgets('sets avatar URL when user profile has photo', (tester) async {
    const testEmail = 'test@example.com';
    const credentialId = 'test-credential-id';
    const avatarUrl = 'https://example.com/avatar.jpg';

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      originalOnError!.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    fakeAuthManager.setCurrentCredential(
      UserCredential(
        id: credentialId,
        email: testEmail,
        metadata: {},
        createdAt: clock.now(),
      ),
    );

    fakeAuthRepository.setUserProfile(
      createUser(
        credentialId: credentialId,
        email: testEmail,
        profilePhotoUrl: avatarUrl,
      ),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(makeApp());
    });
    await tester.pump();

    final coreAvatarFinder = find.byWidgetPredicate(
      (widget) => widget is CoreAvatar && widget.image is NetworkImage,
    );
    expect(coreAvatarFinder, findsOneWidget);

    final coreAvatar = tester.widget<CoreAvatar>(coreAvatarFinder);
    expect((coreAvatar.image! as NetworkImage).url, avatarUrl);
  });

  testWidgets('shows error toast when auth fails', (tester) async {
    fakeAuthManager.setCurrentCredential(
      UserCredential(
        id: 'test-id',
        email: 'test@example.com',
        metadata: {},
        createdAt: clock.now(),
      ),
    );

    fakeAuthRepository.shouldThrowOnGetUserProfile = true;

    await tester.runAsync(() async {
      await tester.pumpWidget(makeApp());
    });

    await tester.pump();

    expect(find.text('Close'), findsOneWidget);
  });
}
