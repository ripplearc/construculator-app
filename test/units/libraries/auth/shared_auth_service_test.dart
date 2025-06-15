import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/shared_auth_service.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthNotifier authNotifier;
  late FakeAuthRepository authRepository;
  late SharedAuthService authService;

  setUp(() {
    authNotifier = FakeAuthNotifier();
    authRepository = FakeAuthRepository();

    authService = SharedAuthService(
      notifier: authNotifier,
      repository: authRepository,
    );
  });

  tearDown(() {
    authNotifier.dispose();
    authRepository.dispose();
  });

  group('Authentication Methods', () {
    test('loginWithEmail should return true on successful login', () async {
      authRepository.reset();
      final result = await authService.loginWithEmail(
        'test@example.com',
        'password',
      );
      expect(result, true);
      expect(authRepository.loginCalls, contains('test@example.com:password'));
      expect(authRepository.loginCalls.length, 1);
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('loginWithEmail should return false when login fails', () async {
      authRepository.fakeAuthResponse(succeed: false);
      final result = await authService.loginWithEmail(
        'fail@example.com',
        'password',
      );
      expect(result, false);
      expect(authRepository.loginCalls, contains('fail@example.com:password'));
      expect(authRepository.loginCalls.length, 1);
      expect(authRepository.registerCalls, isEmpty);
    });

    test('loginWithEmail should handle empty email', () async {
      authRepository.reset();
      final result = await authService.loginWithEmail('', 'password');
      expect(result, false);
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('loginWithEmail should handle empty password', () async {
      authRepository.reset();
      final result = await authService.loginWithEmail('test@example.com', '');
      expect(result, false);
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test(
      'loginWithEmail should handle network exceptions gracefully',
      () async {
        authRepository.shouldThrowOnLogin = true;
        authRepository.exceptionMessage = 'Network connection failed';
        final result = await authService.loginWithEmail(
          'test@example.com',
          'password123',
        );
        expect(result, isFalse);
        expect(result, isNot(isTrue));
        expect(
          authRepository.loginCalls,
          contains('test@example.com:password123'),
        );
        expect(authRepository.registerCalls, isEmpty);
      },
    );

    test(
      'loginWithEmail should return false when repository returns success but null data',
      () async {
        authRepository.reset();
        authRepository.returnSuccessWithNullData = true;
        final result = await authService.loginWithEmail(
          'test@example.com',
          'password',
        );
        expect(
          result,
          false,
          reason: 'Should return false when data is null despite success',
        );
        expect(
          authRepository.loginCalls,
          contains('test@example.com:password'),
        );
        expect(authRepository.loginCalls.length, 1);
        expect(authRepository.registerCalls, isEmpty);
      },
    );

    test(
      'registerWithEmail should return true on successful registration',
      () async {
        authRepository.reset();
        final result = await authService.registerWithEmail(
          'test@example.com',
          'password',
        );
        expect(result, true);
        expect(
          authRepository.registerCalls,
          contains('test@example.com:password'),
        );
        expect(authRepository.registerCalls.length, 1);
        expect(authRepository.loginCalls, isEmpty);
        expect(authRepository.logoutCalls, isEmpty);
      },
    );

    test(
      'registerWithEmail should return false when registration fails',
      () async {
        authRepository.fakeAuthResponse(succeed: false);
        final result = await authService.registerWithEmail(
          'fail@example.com',
          'password',
        );
        expect(result, false);
        expect(
          authRepository.registerCalls,
          contains('fail@example.com:password'),
        );
        expect(authRepository.registerCalls.length, 1);
        expect(authRepository.loginCalls, isEmpty);
      },
    );

    test('registerWithEmail should handle empty email', () async {
      authRepository.reset();
      final result = await authService.registerWithEmail('', 'password');
      expect(result, false);
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('registerWithEmail should handle empty password', () async {
      authRepository.reset();
      final result = await authService.registerWithEmail(
        'test@example.com',
        '',
      );
      expect(result, false);
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test(
      'registerWithEmail should handle network exceptions gracefully',
      () async {
        authRepository.shouldThrowOnRegister = true;
        authRepository.exceptionMessage = 'Network connection failed';
        final result = await authService.registerWithEmail(
          'test@example.com',
          'password123',
        );
        expect(result, isFalse);
        expect(result, isNot(isTrue));
        expect(
          authRepository.registerCalls,
          contains('test@example.com:password123'),
        );
        expect(authRepository.loginCalls, isEmpty);
      },
    );

    test(
      'registerWithEmail should return false when repository returns success but null data',
      () async {
        authRepository.reset();
        authRepository.returnSuccessWithNullData = true;
        final result = await authService.registerWithEmail(
          'test@example.com',
          'password',
        );
        expect(result, false);
        expect(
          authRepository.registerCalls,
          contains('test@example.com:password'),
        );
        expect(authRepository.registerCalls.length, 1);
        expect(authRepository.loginCalls, isEmpty);
      },
    );

    test('isAuthenticated should return true when user is authenticated', () {
      authRepository = FakeAuthRepository(startAuthenticated: true);
      authService = SharedAuthService(
        notifier: authNotifier,
        repository: authRepository,
      );
      final result = authService.isAuthenticated();
      expect(result, true);
    });

    test(
      'isAuthenticated should return false when user is not authenticated',
      () {
        final result = authService.isAuthenticated();
        expect(result, false);
      },
    );

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
      expect(
        authNotifier.stateChangedEvents.contains(AuthStatus.authenticated),
        true,
      ); // Check if the auth state changed to authenticated
    });

    test('logout should emit unauthenticated state', () async {
      authRepository = FakeAuthRepository(startAuthenticated: true);

      authService = SharedAuthService(
        notifier: authNotifier,
        repository: authRepository,
      );

      await authService.logout();
      expect(authRepository.logoutCalls.length, 1);
      // Allow time for notifier to process the logout event
      await Future.delayed(const Duration(milliseconds: 100));
      expect(authNotifier.logoutEvents.length, 1);
      expect(
        authNotifier.stateChangedEvents.contains(AuthStatus.unauthenticated),
        true,
      );
    });

    test(
      'setup profile event should be emitted when profile not found',
      () async {
        authRepository = FakeAuthRepository(startAuthenticated: true);
        authRepository.returnNullUserProfile = true;

        // Re-create the service configured with the auth repository state
        authService = SharedAuthService(
          notifier: authNotifier,
          repository: authRepository,
        );

        // setupProfile event should be emitted when profile not found
        await authService.getUserInfo();

        // Allow time for notifier to process the setup profile event
        await Future.delayed(const Duration(milliseconds: 100));
        expect(authNotifier.setupProfileEvents.length, 1);
      },
    );
    test(
      'resetPassword should return true when email is sent successfully',
      () async {
        final result = await authService.resetPassword('test@example.com');

        expect(result, true);
        expect(authRepository.resetPasswordCalls, contains('test@example.com'));
        expect(authRepository.resetPasswordCalls.length, 1);
      },
    );

    test(
      'resetPassword should return false when email fails to send',
      () async {
        authRepository.fakeAuthResponse(succeed: false);

        final result = await authService.resetPassword('fail@example.com');

        expect(result, false);
        expect(authRepository.resetPasswordCalls, contains('fail@example.com'));
        expect(authRepository.resetPasswordCalls.length, 1);
      },
    );

    test('resetPassword should handle network exceptions gracefully', () async {
      authRepository.shouldThrowOnResetPassword = true;
      authRepository.exceptionMessage = 'Network connection failed';

      final result = await authService.resetPassword('test@example.com');

      expect(result, isFalse);
      expect(result, isNot(isTrue));
      expect(authRepository.resetPasswordCalls, contains('test@example.com'));
    });

    test('isEmailRegistered should return true for registered email', () async {
      const testEmail = 'registered@example.com';

      final result = await authService.isEmailRegistered(testEmail);

      expect(result, true);
      expect(authRepository.emailCheckCalls, contains(testEmail));
      expect(authRepository.emailCheckCalls.length, 1);
    });

    test(
      'isEmailRegistered should return false for unregistered email',
      () async {
        final result = await authService.isEmailRegistered(
          'unknown@example.com',
        );

        expect(result, false);
        expect(authRepository.emailCheckCalls, contains('unknown@example.com'));
        expect(authRepository.emailCheckCalls.length, 1);
      },
    );

    test('isEmailRegistered should return false when check fails', () async {
      authRepository.fakeAuthResponse(succeed: false);

      final result = await authService.isEmailRegistered('fail@example.com');

      expect(result, false);
      expect(authRepository.emailCheckCalls, contains('fail@example.com'));
      expect(authRepository.emailCheckCalls.length, 1);
    });

    test(
      'isEmailRegistered should handle network exceptions gracefully',
      () async {
        authRepository.shouldThrowOnEmailCheck = true;
        authRepository.exceptionMessage = 'Network connection failed';

        final result = await authService.isEmailRegistered('test@example.com');

        expect(result, isFalse);
        expect(result, isNot(isTrue));
        expect(authRepository.emailCheckCalls, contains('test@example.com'));
      },
    );

    test('getCurrentUser should return null when not authenticated', () async {
      authRepository = FakeAuthRepository(startAuthenticated: false);
      authService = SharedAuthService(
        notifier: authNotifier,
        repository: authRepository,
      );

      final userCredential = await authService.getCurrentUser();

      expect(userCredential, isNull);
      expect(authRepository.getCurrentUserCallCount, 1);
    });

    test(
      'getCurrentUser should return credentials when authenticated',
      () async {
        final repo = FakeAuthRepository(startAuthenticated: true);
        final notifier = FakeAuthNotifier();
        final authService = SharedAuthService(
          notifier: notifier,
          repository: repo,
        );

        final credential = await authService.getCurrentUser();

        expect(credential, isNotNull);
        expect(credential?.email, isNotNull);
        expect(credential?.id, isNotNull);
        expect(repo.getCurrentUserCallCount, 2);
      },
    );

    test('user can retry login after a failed attempt', () async {
      authRepository.fakeAuthResponse(succeed: false);
      final firstAttempt = await authService.loginWithEmail(
        'test@example.com',
        'wrong',
      );
      expect(firstAttempt, false);

      authRepository.fakeAuthResponse(succeed: true);

      final secondAttempt = await authService.loginWithEmail(
        'test@example.com',
        'correct',
      );

      expect(secondAttempt, true);
      expect(
        authRepository.loginCalls,
        containsAll(['test@example.com:wrong', 'test@example.com:correct']),
      );
      expect(authRepository.loginCalls.length, 2);
    });

    test('getUserInfo should return user profile when it exists', () async {
      final testCredential = UserCredential(
        id: 'test-user-id',
        email: 'test@example.com',
        metadata: {},
        createdAt: DateTime.now(),
      );

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

      authRepository.emitAuthStateChanged(AuthStatus.authenticated);
      authRepository.emitUserUpdated(testCredential);

      await Future.delayed(const Duration(milliseconds: 50));

      final userInfo = await authService.getUserInfo();

      expect(userInfo, isNotNull);
      expect(userInfo?.email, 'test@example.com');
      expect(userInfo?.firstName, 'Test');
      expect(userInfo?.lastName, 'User');
      expect(userInfo?.professionalRole, 'Developer');
      expect(userInfo?.userStatus, UserProfileStatus.active);
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
      expect(authRepository.getUserProfileCalls.length, 1);
    });

    test(
      'getUserInfo should return null when profile retrieval succeeds but returns null data',
      () async {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'test@example.com',
          metadata: {},
          createdAt: DateTime.now(),
        );

        authRepository.emitAuthStateChanged(AuthStatus.authenticated);
        authRepository.emitUserUpdated(testCredential);

        authRepository.returnSuccessWithNullUserProfile = true;

        final userInfo = await authService.getUserInfo();

        expect(
          userInfo,
          isNull,
          reason:
              'Should return null when profile data is null despite success',
        );
        expect(authRepository.getUserProfileCalls, contains('test-id'));
        expect(authRepository.getUserProfileCalls.length, 1);
      },
    );

    test(
      'getUserInfo should return null when no user is authenticated',
      () async {
        authRepository = FakeAuthRepository(startAuthenticated: false);
        authService = SharedAuthService(
          notifier: authNotifier,
          repository: authRepository,
        );

        final userInfo = await authService.getUserInfo();

        expect(userInfo, isNull);
      },
    );

    test('logout should work correctly', () async {
      await authService.logout();

      expect(authRepository.logoutCalls, isNotEmpty);
      expect(authRepository.logoutCalls.length, 1);
    });

    test('sendOtp should return true when OTP is sent successfully', () async {
      final result = await authService.sendOtp(
        'test@example.com',
        OtpReceiver.email,
      );

      expect(result, true);
      expect(
        authRepository.sendOtpCalls,
        contains('test@example.com:OtpReceiver.email'),
      );
      expect(authRepository.sendOtpCalls.length, 1);
      expect(authRepository.getSentOtp('test@example.com'), isNotNull);
    });

    test('sendOtp should return false when sending OTP fails', () async {
      authRepository.fakeAuthResponse(succeed: false);

      final result = await authService.sendOtp(
        'fail@example.com',
        OtpReceiver.email,
      );

      expect(result, false);
      expect(
        authRepository.sendOtpCalls,
        contains('fail@example.com:OtpReceiver.email'),
      );
      expect(authRepository.sendOtpCalls.length, 1);
    });

    test('sendOtp should handle network exceptions gracefully', () async {
      authRepository.shouldThrowOnSendOtp = true;
      authRepository.exceptionMessage = 'Network connection failed';

      final result = await authService.sendOtp(
        'test@example.com',
        OtpReceiver.email,
      );

      expect(result, isFalse);
      expect(result, isNot(isTrue));
      expect(
        authRepository.sendOtpCalls,
        contains('test@example.com:OtpReceiver.email'),
      );
    });

    test('verifyOtp should return true for valid OTP', () async {
      final email = 'test@example.com';
      await authService.sendOtp(email, OtpReceiver.email);
      final sentOtp = authRepository.getSentOtp(email)!;

      final result = await authService.verifyOtp(
        email,
        sentOtp,
        OtpReceiver.email,
      );

      expect(result, true);
      expect(
        authRepository.verifyOtpCalls,
        contains('$email:$sentOtp:OtpReceiver.email'),
      );
      expect(authRepository.verifyOtpCalls.length, 1);
    });

    test('verifyOtp should return false for invalid OTP', () async {
      final email = 'test@example.com';
      await authService.sendOtp(email, OtpReceiver.email);

      final result = await authService.verifyOtp(
        email,
        'invalid',
        OtpReceiver.email,
      );

      expect(result, false);
      expect(
        authRepository.verifyOtpCalls,
        contains('$email:invalid:OtpReceiver.email'),
      );
      expect(authRepository.verifyOtpCalls.length, 1);
    });

    test('verifyOtp should handle network exceptions gracefully', () async {
      authRepository.shouldThrowOnVerifyOtp = true;
      authRepository.exceptionMessage = 'Network connection failed';

      final result = await authService.verifyOtp(
        'test@example.com',
        '123456',
        OtpReceiver.email,
      );

      expect(result, isFalse);
      expect(result, isNot(isTrue));
      expect(
        authRepository.verifyOtpCalls,
        contains('test@example.com:123456:OtpReceiver.email'),
      );
    });
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
      authRepository.reset(
        authenticated: true,
      ); // Ensures there is a current user ID
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
        authRepository.returnNullUserProfile =
            true; // getAuthUserProfile returns success but null data

        final result = await authService.getUserInfo();

        // Allow time for notifier to process the setup profile event
        await Future.delayed(const Duration(milliseconds: 10));

        expect(result, isNull);
        expect(authRepository.getUserProfileCalls, contains('test-user-id'));
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
