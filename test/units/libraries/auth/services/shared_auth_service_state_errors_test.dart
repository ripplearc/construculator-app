import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/logging/testing/fake_logger_wrapper.dart';
import 'package:construculator/libraries/logging/testing/test_app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/shared_auth_service.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

void main() {
  // Initialize the testing environment
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up our minimal test environment
  late FakeAuthNotifier authNotifier;
  late FakeAuthRepository authRepository;
  late SharedAuthService authService;
  late TestAppLogger fakeLogger;

  setUp(() {
    fakeLogger = TestAppLogger(internalLogger: FakeLoggerWrapper());
    authNotifier = FakeAuthNotifier();
    authRepository = FakeAuthRepository();

    authService = SharedAuthService(
      notifier: authNotifier,
      repository: authRepository,
      logger: fakeLogger,
    );
  });

  tearDown(() {
    authNotifier.dispose();
    authRepository.dispose();
  });

  group('Auth State Management', () {

    test('successful login should emit correct auth state', () async {

      final result = await authService.loginWithEmail(
        'test@example.com',
        'password',
      );
      expect(result, true);
      // Allow time for notifier to process the login event
      await Future.delayed(const Duration(milliseconds: 100));
      expect(authNotifier.loginEvents.first.email, 'test@example.com');
      expect(authNotifier.loginEvents.length, 1);
      expect(authNotifier.stateChangedEvents.contains(AuthStatus.authenticated), true); // Check if the auth state changed to authenticated
    });

    test('logout should emit unauthenticated state', () async {
      authRepository = FakeAuthRepository(startAuthenticated: true);

      authService = SharedAuthService(
        notifier: authNotifier,
        repository: authRepository,
        logger: fakeLogger,
      );

      await authService.logout();
      expect(authRepository.logoutCalls.length, 1);
      // Allow time for notifier to process the logout event
      await Future.delayed(const Duration(milliseconds: 100));
      expect(authNotifier.logoutEvents.length, 1);
      expect(authNotifier.stateChangedEvents.contains(AuthStatus.unauthenticated), true);
    });

    test('setup profile event should be emitted when profile not found', () async {
      
      authRepository = FakeAuthRepository(startAuthenticated: true);
      authRepository.returnNullUserProfile = true;

      // Re-create the service configured with the auth repository state
      authService = SharedAuthService(
        notifier: authNotifier,
        repository: authRepository,
        logger: fakeLogger,
      );

      // setupProfile event should be emitted when profile not found
      await authService.getUserInfo();

      // Allow time for notifier to process the setup profile event
      await Future.delayed(const Duration(milliseconds: 100));
      expect(
        authNotifier.setupProfileEvents.length,
        1,
      );
    });
  });

  group('Error Handling and Edge Cases', () {
    test('logout should handle repository failure gracefully', () async {
      authRepository.shouldThrowOnLogout = true;
      authRepository.exceptionMessage = 'Logout failed';

      authRepository.fakeAuthResponse(
        succeed: false,
        errorMessage: 'Logout failed',
      );
      expect(
        () async => await authService.logout(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Logout failed'),
          ),
        ),
      );
      expect(authRepository.logoutCalls.length, 1);
    });
    test('getUserInfo should return null when no current user', () async {
      final result = await authService.getUserInfo();
      expect(result, isNull);
      expect(authRepository.getUserProfileCalls, isEmpty);
    });

    test('getUserInfo should handle profile retrieval failure', () async {
      authRepository.reset(authenticated: true); // Ensures there is a current user ID
      authRepository.fakeAuthResponse(
        succeed:
            false, // This makes getAuthUserProfile in repo return failed AuthResponse
        errorMessage: 'Profile not found',
      );
      final result = await authService.getUserInfo();
      expect(result, isNull);
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
    });

    test(
      'getUserInfo should emit setup profile event when profile not found',
      () async {
        authRepository.reset(authenticated: true);
        authRepository.returnNullUserProfile = true; // getAuthUserProfile returns success but null data

        final result = await authService.getUserInfo();

        // Allow time for notifier to process the setup profile event
        await Future.delayed(const Duration(milliseconds: 10));

        expect(result, isNull);
        expect(
          authRepository.getUserProfileCalls,
          contains('test-user-id'),
        );
        expect(authNotifier.setupProfileEvents.length, 1);
      },
    );

    test(
      'getUserInfo should handle exceptions during profile retrieval',
      () async {
        authRepository.reset(authenticated: true);
        authRepository.shouldThrowOnGetUserProfile = true;
        authRepository.exceptionMessage = 'Database error';

        final result = await authService.getUserInfo();
        expect(result, isNull);
        expect(authRepository.getUserProfileCalls, contains('test-user-id'));
      },
    );

    test('getUserInfo should handle success with null profile data', () async {
      authRepository.reset(authenticated: true);
      authRepository.returnSuccessWithNullUserProfile = true;

      final result = await authService.getUserInfo();
      expect(result, isNull);
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
    });

    test('should handle successful profile retrieval', () async {
      authRepository.reset(authenticated: true);
      final testUser = User(
        id: 'test-user-id',
        credentialId: 'test-user-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Developer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      );
      authRepository.fakeUserProfile(testUser);

      final result = await authService.getUserInfo();

      expect(result, isNotNull);
      expect(result?.id, equals('test-user-id'));
      expect(result?.email, equals('test@example.com'));
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
    });

    test('getCurrentUser should return current credentials', () async {
      authRepository.reset(authenticated: true);
      final result = await authService.getCurrentUser();

      expect(result, isNotNull);
      expect(result?.id, equals('test-user-id'));
      expect(result?.email, equals('test@example.com'));
    });

    test('getCurrentUser should return null when no user', () async {
      final result = await authService.getCurrentUser();
      expect(result, isNull);
    });

    test('isAuthenticated should return repository authentication status', () {
      authRepository.reset(authenticated: true);
      final result = authService.isAuthenticated();

      expect(result, isTrue);
    });

    test('isAuthenticated should return false when not authenticated', () {
      final result = authService.isAuthenticated();
      expect(result, isFalse);
    });

    test('authStateChanges should return repository auth state stream', () {
      final stream = authService.authStateChanges;

      expect(stream, isNotNull);
      expect(stream, equals(authRepository.authStateChanges));
    });

    test('dispose should clean up resources', () {
      expect(() => authService.dispose(), returnsNormally);
    });
  });
}
