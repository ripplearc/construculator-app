import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/dashboard/presentation/widgets/recent_estimations_section.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
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

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  late FakeClockImpl clock;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAuthRepository authRepository;
  late FakeAuthManager authManager;
  late FakeAuthNotifier authNotifier;
  late FakeAppRouter router;

  setUpAll(() async {
    await loadAppFontsAll();

    clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    authNotifier = FakeAuthNotifier();
    authRepository = FakeAuthRepository(clock: clock);
    authManager = FakeAuthManager(
      authNotifier: authNotifier,
      authRepository: authRepository,
      wrapper: fakeSupabase,
      clock: clock,
    );
    router = FakeAppRouter();

    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(DashboardModule(bootstrap));

    Modular.replaceInstance<AuthNotifierController>(authNotifier);
    Modular.replaceInstance<AuthNotifier>(authNotifier);
    Modular.replaceInstance<AuthManager>(authManager);
    Modular.replaceInstance<AppRouter>(router);
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    fakeSupabase.reset();
    router.reset();
    authRepository.returnNullUserProfile = false;
  });

  Widget makeApp() {
    return MaterialApp(
      theme: createTestTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DashboardPage(
        authNotifier: authNotifier,
        authManager: authManager,
        router: router,
        recentEstimationsBloc: Modular.get<RecentEstimationsBloc>(),
      ),
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

  testWidgets('renders RecentEstimationsSection', (tester) async {
    final credential = createCredential();
    final user = createUser();

    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.byType(RecentEstimationsSection), findsOneWidget);
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
