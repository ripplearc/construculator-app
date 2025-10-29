import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_event.dart';
import 'package:construculator/features/auth/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late FakeAuthManager fakeAuthManager;
    late FakeAuthNotifier fakeAuthNotifier;
    late FakeAppRouter fakeRouter;
    late Clock clock;
    late FakeSupabaseWrapper fakeSupabase;

    const testUserId = 'test-user-123';
    const testEmail = 'test@example.com';
    const testAvatarUrl = 'https://example.com/avatar.jpg';

    setUp(() {
      // Create fake dependencies directly instead of using Modular
      clock = FakeClockImpl();
      fakeSupabase = FakeSupabaseWrapper(clock: clock);
      fakeAuthNotifier = FakeAuthNotifier();
      final fakeAuthRepository = FakeAuthRepository(clock: clock);
      fakeAuthManager = FakeAuthManager(
        authNotifier: fakeAuthNotifier,
        authRepository: fakeAuthRepository,
        wrapper: fakeSupabase,
        clock: clock,
      );
      fakeRouter = FakeAppRouter();

      authBloc = AuthBloc(
        authManager: fakeAuthManager,
        authNotifier: fakeAuthNotifier,
        router: fakeRouter,
      );
    });

    tearDown(() {
      fakeAuthManager.reset();
      fakeAuthNotifier.reset();
      fakeRouter.reset();
      fakeSupabase.reset();
      authBloc.close();
    });

    group('AuthStarted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoadInProgress, AuthLoadUnauthenticated] when user is not authenticated',
        build: () {
          fakeAuthManager.setCurrentCredential(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoadInProgress(),
          const AuthLoadUnauthenticated(),
        ],
        verify: (_) {
          expect(fakeRouter.navigationHistory.any((call) => call.route == fullLoginRoute), isTrue);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoadInProgress, AuthLoadSuccess] when user is authenticated and profile loads successfully',
        build: () {
          final testCredential = UserCredential(
            id: testUserId,
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          );
          
          final testUser = User(
            id: testUserId,
            credentialId: testUserId,
            email: testEmail,
            firstName: 'Test',
            lastName: 'User',
            professionalRole: 'manager',
            userStatus: UserProfileStatus.active,
            createdAt: clock.now(),
            updatedAt: clock.now(),
            userPreferences: {},
          );
          
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthManager.setAuthResponse(succeed: true);
          
          // Set up the fake repository to return the test user
          final fakeRepository = fakeAuthManager.authRepository as FakeAuthRepository;
          fakeRepository.setUserProfile(testUser);

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoadInProgress(),
          isA<AuthLoadSuccess>()
              .having((s) => s.user!.id, 'user.id', testUserId),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoadInProgress, AuthLoadUnauthenticated] when user profile is not found',
        build: () {
          final testCredential = UserCredential(
            id: testUserId,
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          );
          
          fakeAuthManager.setCurrentCredential(testCredential);
          // Don't set auth response to fail here - we want the credential to be available
          // but we want the getUserProfile call to fail
          
          // Set up the fake repository to return null user profile
          final fakeRepository = fakeAuthManager.authRepository as FakeAuthRepository;
          fakeRepository.returnNullUserProfile = true;

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoadInProgress(),
          const AuthLoadUnauthenticated(),
        ],
        verify: (_) {
          expect(fakeRouter.navigationHistory.any((call) => call.route == fullCreateAccountRoute), isTrue);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoadInProgress, AuthLoadFailure] when profile loading fails with error',
        build: () {
          final testCredential = UserCredential(
            id: testUserId,
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          );
          
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthManager.setAuthResponse(succeed: true); // Allow auth manager to succeed
          
          // Set up the fake repository to throw an exception
          final fakeRepository = fakeAuthManager.authRepository as FakeAuthRepository;
          fakeRepository.shouldThrowOnGetUserProfile = true;
          fakeRepository.exceptionMessage = 'Server error during profile loading';

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoadInProgress(),
          isA<AuthLoadFailure>()
              .having((s) => s.message, 'message', isNotEmpty),
        ],
      );
    });

    group('AuthUserProfileChanged', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoadUnauthenticated] when user profile is null',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthUserProfileChanged(null)),
        expect: () => [
          const AuthLoadUnauthenticated(),
        ],
        verify: (_) {
          expect(fakeRouter.navigationHistory.any((call) => call.route == fullCreateAccountRoute), isTrue);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoadSuccess] when user profile is provided',
        build: () => authBloc,
        act: (bloc) {
          final testUser = User(
            id: testUserId,
            email: testEmail,
            firstName: 'Jane',
            lastName: 'Smith',
            profilePhotoUrl: testAvatarUrl,
            professionalRole: 'manager',
            userStatus: UserProfileStatus.active,
            createdAt: clock.now(),
            updatedAt: clock.now(),
            userPreferences: {},
          );
          bloc.add(AuthUserProfileChanged(testUser));
        },
        expect: () => [
          isA<AuthLoadSuccess>()
              .having((s) => s.user!.id, 'user.id', testUserId)
              .having((s) => s.user!.firstName, 'user.firstName', 'Jane')
              .having((s) => s.avatarUrl, 'avatarUrl', testAvatarUrl),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoadSuccess] when user profile has no avatar URL',
        build: () => authBloc,
        act: (bloc) {
          final testUser = User(
            id: testUserId,
            email: testEmail,
            firstName: 'Bob',
            lastName: 'Johnson',
            profilePhotoUrl: null,
            professionalRole: 'architect',
            userStatus: UserProfileStatus.active,
            createdAt: clock.now(),
            updatedAt: clock.now(),
            userPreferences: {},
          );
          bloc.add(AuthUserProfileChanged(testUser));
        },
        expect: () => [
          isA<AuthLoadSuccess>()
              .having((s) => s.user!.id, 'user.id', testUserId)
              .having((s) => s.user!.firstName, 'user.firstName', 'Bob')
              .having((s) => s.avatarUrl, 'avatarUrl', null),
        ],
      );
    });

    group('Multiple sequential event and state tests', () {
      blocTest<AuthBloc, AuthState>(
        'handles multiple events in sequence correctly',
        build: () {
          final testCredential = UserCredential(
            id: testUserId,
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          );
          
          final testUser = User(
            id: testUserId,
            credentialId: testUserId,
            email: testEmail,
            firstName: 'Test',
            lastName: 'User',
            professionalRole: 'manager',
            userStatus: UserProfileStatus.active,
            createdAt: clock.now(),
            updatedAt: clock.now(),
            userPreferences: {},
          );
          
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthManager.setAuthResponse(succeed: true);
          
          // Set up the fake repository to return the test user
          final fakeRepository = fakeAuthManager.authRepository as FakeAuthRepository;
          fakeRepository.setUserProfile(testUser);

          return authBloc;
        },
        act: (bloc) async {
          bloc.add(const AuthStarted());
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(AuthUserProfileChanged(null));
        },
        expect: () => [
          const AuthLoadInProgress(),
          isA<AuthLoadSuccess>()
              .having((s) => s.user!.id, 'user.id', testUserId),
          const AuthLoadUnauthenticated(),
        ],
      );
    });

    group('Cases where AuthBloc receives null parameters', () {
      blocTest<AuthBloc, AuthState>(
        'handles AuthStarted when credentials are null',
        build: () {
          fakeAuthManager.setCurrentCredential(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoadInProgress(),
          const AuthLoadUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'handles AuthStarted when user ID is null',
        build: () {
          final testCredential = UserCredential(
            id: '',
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          );
          
          fakeAuthManager.setCurrentCredential(testCredential);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoadInProgress(),
          const AuthLoadUnauthenticated(),
        ],
      );
    });

    group('Error Handling', () {
      blocTest<AuthBloc, AuthState>(
        'handles exceptions during profile loading',
        build: () {
          final testCredential = UserCredential(
            id: testUserId,
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          );
          
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthManager.setAuthResponse(succeed: true); // Allow auth manager to succeed
          
          // Set up the fake repository to throw an exception
          final fakeRepository = fakeAuthManager.authRepository as FakeAuthRepository;
          fakeRepository.shouldThrowOnGetUserProfile = true;
          fakeRepository.exceptionMessage = 'Server error during profile loading';

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoadInProgress(),
          isA<AuthLoadFailure>()
              .having((s) => s.message, 'message', isNotEmpty),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'handles network timeout errors',
        build: () {
          final testCredential = UserCredential(
            id: testUserId,
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          );
          
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthManager.setAuthResponse(succeed: true); // Allow auth manager to succeed
          
          // Set up the fake repository to throw an exception
          final fakeRepository = fakeAuthManager.authRepository as FakeAuthRepository;
          fakeRepository.shouldThrowOnGetUserProfile = true;
          fakeRepository.exceptionMessage = 'Network timeout error';

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoadInProgress(),
          isA<AuthLoadFailure>()
              .having((s) => s.message, 'message', isNotEmpty),
        ],
      );
    });
  });
}