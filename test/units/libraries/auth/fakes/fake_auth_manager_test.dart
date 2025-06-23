import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthManager authManager;
  late FakeAuthNotifier authNotifier;
  late FakeAuthRepository authRepository;

  const testEmail = 'test@example.com';
  const testPassword = '5i2Un@D8Y9!';
  const testUserId = 'test-test';

  setUp(() {
    Modular.init(_TestAppModule());
    authNotifier = Modular.get<AuthNotifierController>() as FakeAuthNotifier;
    authRepository = Modular.get<AuthRepository>() as FakeAuthRepository;
    authManager = Modular.get<AuthManager>() as FakeAuthManager;
  });

  tearDown(() {
    Modular.destroy();
  });

  group('FakeAuthManager', () {
    test('getCurrentCredentials should return null and isAuthenticated should be false on initialization', () {
      expect(authManager.isAuthenticated(), false);
      expect(authManager.getCurrentCredentials().data, null);
      expect(authNotifier.stateChangedEvents.length, 1);
      expect(
        authNotifier.stateChangedEvents.first.status,
        AuthStatus.unauthenticated,
      );
    });

    group('Input Validation', () {
      group('loginWithEmail validation', () {
        test('loginWithEmail should reject empty email with invalidCredentials error', () async {
          final result = await authManager.loginWithEmail('', testPassword);

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, AuthValidationErrorType.emailRequired.message);
          expect(authManager.loginAttempts.length, 1);
          expect(authManager.loginAttempts.first.email, '');
        });

        test('loginWithEmail should reject invalid email format with invalidCredentials error', () async {
          final result = await authManager.loginWithEmail(
            'invalid-email',
            testPassword,
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, 'Please enter a valid email address');
          expect(authManager.loginAttempts.length, 1);
          expect(authManager.loginAttempts.first.email, 'invalid-email');
        });

        test('loginWithEmail should succeed with valid email format', () async {
          final result = await authManager.loginWithEmail(
            'user@example.com',
            testPassword,
          );

          expect(result.isSuccess, true);
          expect(authManager.loginAttempts.length, 1);
          expect(authManager.loginAttempts.first.email, 'user@example.com');
        });
      });

      group('password validation', () {
        test('loginWithEmail should reject empty password with invalidCredentials error', () async {
          final result = await authManager.loginWithEmail(testEmail, '');

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, AuthValidationErrorType.passwordRequired.message);
          expect(authManager.loginAttempts.length, 1);
          expect(authManager.loginAttempts.first.password, '');
        });

        test('loginWithEmail should accept any non-empty password', () async {
          final result = await authManager.loginWithEmail(testEmail, 'a');

          expect(result.isSuccess, true);
          expect(authManager.loginAttempts.length, 1);
          expect(authManager.loginAttempts.first.password, 'a');
        });
      });

      group('OTP validation', () {
        test('verifyOtp should reject empty OTP with invalidCredentials error', () async {
          final result = await authManager.verifyOtp(
            testEmail,
            '',
            OtpReceiver.email,
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(
            result.errorMessage,
            AuthValidationErrorType.otpRequired.message,
          );
          expect(authManager.otpVerificationAttempts.length, 1);
          expect(authManager.otpVerificationAttempts.first.otp, '');
        });

        test('verifyOtp should reject short OTP with invalidCredentials error', () async {
          final result = await authManager.verifyOtp(
            testEmail,
            '12345',
            OtpReceiver.email,
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(
            result.errorMessage,
            AuthValidationErrorType.invalidOtp.message,
          );
          expect(authManager.otpVerificationAttempts.length, 1);
          expect(authManager.otpVerificationAttempts.first.otp, '12345');
        });

        test('verifyOtp should reject long OTP with invalidCredentials error', () async {
          final result = await authManager.verifyOtp(
            testEmail,
            '1234567',
            OtpReceiver.email,
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(
            result.errorMessage,
            AuthValidationErrorType.invalidOtp.message,
          );
          expect(authManager.otpVerificationAttempts.length, 1);
          expect(authManager.otpVerificationAttempts.first.otp, '1234567');
        });

        test('verifyOtp should reject invalid email with invalidCredentials error', () async {
          final result = await authManager.verifyOtp(
            'invalid-email',
            '1234567',
            OtpReceiver.email,
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, 'Please enter a valid email address');
          expect(authManager.otpVerificationAttempts.length, 1);
          expect(authManager.otpVerificationAttempts.first.otp, '1234567');
        });

        test('verifyOtp should reject non-numeric OTP with invalidCredentials error', () async {
          final result = await authManager.verifyOtp(
            testEmail,
            '12a456',
            OtpReceiver.email,
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(
            result.errorMessage,
            AuthValidationErrorType.invalidOtp.message,
          );
          expect(authManager.otpVerificationAttempts.length, 1);
          expect(authManager.otpVerificationAttempts.first.otp, '12a456');
        });

        test('verifyOtp should accept valid OTP format', () async {
          final result = await authManager.verifyOtp(
            testEmail,
            '123456',
            OtpReceiver.email,
          );

          expect(result.isSuccess, true);
          expect(authManager.otpVerificationAttempts.length, 1);
          expect(authManager.otpVerificationAttempts.first.otp, '123456');
        });
      });

      group('validation across operations', () {
        test('sendOtp should reject invalid email with invalidCredentials error', () async {
          final result = await authManager.sendOtp(
            'invalid-email',
            OtpReceiver.email,
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, 'Please enter a valid email address');
          expect(authManager.otpSendAttempts.length, 1);
          expect(authManager.otpSendAttempts.first.address, 'invalid-email');
        });

        test('resetPassword should reject invalid email with invalidCredentials error', () async {
          final result = await authManager.resetPassword('invalid-email');

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, 'Please enter a valid email address');
          expect(authManager.passwordResetAttempts.length, 1);
          expect(authManager.passwordResetAttempts.first, 'invalid-email');
        });

        test('isEmailRegistered should reject invalid email with invalidCredentials error', () async {
          final result = await authManager.isEmailRegistered('invalid-email');

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, 'Please enter a valid email address');
          expect(authManager.emailCheckAttempts.length, 1);
          expect(authManager.emailCheckAttempts.first, 'invalid-email');
        });

        test('registerWithEmail should reject invalid email with invalidCredentials error', () async {
          final result = await authManager.registerWithEmail(
            'invalid-email',
            testPassword,
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, 'Please enter a valid email address');
          expect(authManager.registrationAttempts.length, 1);
          expect(authManager.registrationAttempts.first.email, 'invalid-email');
        });

        test('registerWithEmail should reject empty password with invalidCredentials error', () async {
          final result = await authManager.registerWithEmail(testEmail, '');

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
          expect(result.errorMessage, AuthValidationErrorType.passwordRequired.message);
          expect(authManager.registrationAttempts.length, 1);
          expect(authManager.registrationAttempts.first.password, '');
        });
      });
    });

    group('setAuthResponse configuration', () {
      test('setAuthResponse should properly configure authentication response behavior', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Custom error',
          errorType: AuthErrorType.invalidCredentials,
        );

        final result = await authManager.loginWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Custom error');
        expect(result.errorType, AuthErrorType.invalidCredentials);

        authManager.setAuthResponse(succeed: true);

        final successResult = await authManager.loginWithEmail(
          testEmail,
          testPassword,
        );

        expect(successResult.isSuccess, true);
      });
    });

    group('Authentication Operations', () {
      test('loginWithEmail should update state and track attempt on success', () async {
        final result = await authManager.loginWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        expect(result.data!.id, 'test-test');
        expect(authManager.isAuthenticated(), true);
        expect(authManager.loginAttempts.length, 1);
        expect(authManager.loginAttempts.first.email, testEmail);
        expect(authManager.loginAttempts.first.password, testPassword);
        expect(authNotifier.stateChangedEvents.length, 2);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.authenticated,
        );
      });

      test('loginWithEmail should return error and not update state on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Invalid credentials',
          errorType: AuthErrorType.invalidCredentials,
        );

        final result = await authManager.loginWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Invalid credentials');
        expect(result.errorType, AuthErrorType.invalidCredentials);
        expect(authManager.isAuthenticated(), false);
        expect(authManager.loginAttempts.length, 1);
        expect(authNotifier.stateChangedEvents.length, 1);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.unauthenticated,
        );
      });

      test('registerWithEmail should update state and track attempt on success', () async {
        final result = await authManager.registerWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        expect(result.data!.id, 'test-test');
        expect(authManager.isAuthenticated(), true);
        expect(authManager.registrationAttempts.length, 1);
        expect(authManager.registrationAttempts.first.email, testEmail);
        expect(authManager.registrationAttempts.first.password, testPassword);
        expect(authNotifier.stateChangedEvents.length, 2);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.authenticated,
        );
      });

      test('registerWithEmail should return error and not update state on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Registration failed',
          errorType: AuthErrorType.registrationFailure,
        );

        final result = await authManager.registerWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Registration failed');
        expect(result.errorType, AuthErrorType.registrationFailure);
        expect(authManager.isAuthenticated(), false);
        expect(authManager.registrationAttempts.length, 1);
        expect(authNotifier.stateChangedEvents.length, 1);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.unauthenticated,
        );
      });
    });

    group('OTP Operations', () {
      test('sendOtp should track attempt and return success', () async {
        final result = await authManager.sendOtp(testEmail, OtpReceiver.email);

        expect(result.isSuccess, true);
        expect(authManager.otpSendAttempts.length, 1);
        expect(authManager.otpSendAttempts.first.address, testEmail);
        expect(authManager.otpSendAttempts.first.receiver, OtpReceiver.email);
      });

      test('sendOtp should return error on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Failed to send OTP',
          errorType: AuthErrorType.serverError,
        );

        final result = await authManager.sendOtp(testEmail, OtpReceiver.email);

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Failed to send OTP');
        expect(result.errorType, AuthErrorType.serverError);
        expect(authManager.otpSendAttempts.length, 1);
      });

      test('verifyOtp should update state and track attempt on success', () async {
        final result = await authManager.verifyOtp(
          testEmail,
          '123456',
          OtpReceiver.email,
        );

        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        expect(authManager.isAuthenticated(), true);
        expect(authManager.otpVerificationAttempts.length, 1);
        expect(authManager.otpVerificationAttempts.first.address, testEmail);
        expect(authManager.otpVerificationAttempts.first.otp, '123456');
        expect(authNotifier.stateChangedEvents.length, 2);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.authenticated,
        );
      });

      test('verifyOtp should return error and not update state on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Invalid verification code',
          errorType: AuthErrorType.invalidCredentials,
        );

        final result = await authManager.verifyOtp(
          testEmail,
          '123456',
          OtpReceiver.email,
        );

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Invalid verification code');
        expect(result.errorType, AuthErrorType.invalidCredentials);
        expect(authManager.isAuthenticated(), false);
        expect(authManager.otpVerificationAttempts.length, 1);
        expect(authNotifier.stateChangedEvents.length, 1);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.unauthenticated,
        );
      });
    });

    group('Password Reset', () {
      test('resetPassword should track attempt and return success', () async {
        final result = await authManager.resetPassword(testEmail);

        expect(result.isSuccess, true);
        expect(result.data, true);
        expect(authManager.passwordResetAttempts.length, 1);
        expect(authManager.passwordResetAttempts.first, testEmail);
      });

      test('resetPassword should return error on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Password reset failed',
          errorType: AuthErrorType.serverError,
        );

        final result = await authManager.resetPassword(testEmail);

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Password reset failed');
        expect(result.errorType, AuthErrorType.serverError);
        expect(authManager.passwordResetAttempts.length, 1);
      });
    });

    group('Email Registration Check', () {
      test('isEmailRegistered should track attempt and return success', () async {
        final result = await authManager.isEmailRegistered(testEmail);

        expect(result.isSuccess, true);
        expect(result.data, true);
        expect(authManager.emailCheckAttempts.length, 1);
        expect(authManager.emailCheckAttempts.first, testEmail);
      });

      test('isEmailRegistered should return error on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Email check failed',
          errorType: AuthErrorType.serverError,
        );

        final result = await authManager.isEmailRegistered(testEmail);

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Email check failed');
        expect(result.errorType, AuthErrorType.serverError);
        expect(authManager.emailCheckAttempts.length, 1);
      });
    });

    group('Logout', () {
      test('logout should clear state and track attempt on success', () async {
        await authManager.loginWithEmail(testEmail, testPassword);
        authNotifier.stateChangedEvents.clear();

        final result = await authManager.logout();

        expect(result.isSuccess, true);
        expect(authManager.isAuthenticated(), false);
        expect(authManager.logoutAttempts.length, 1);
        expect(authManager.getCurrentCredentials().data, null);
        expect(authNotifier.stateChangedEvents.length, 1);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.unauthenticated,
        );
      });

      test('logout should return error and maintain state on failure', () async {
        await authManager.loginWithEmail(testEmail, testPassword);
        authNotifier.stateChangedEvents.clear();

        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Logout failed',
          errorType: AuthErrorType.serverError,
        );

        final result = await authManager.logout();

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Logout failed');
        expect(result.errorType, AuthErrorType.serverError);
        expect(authManager.isAuthenticated(), true);
        expect(authManager.logoutAttempts.length, 1);
        expect(authNotifier.stateChangedEvents.isEmpty, true);
      });
    });

    group('User Profile Management', () {
      final testUser = User(
        id: testUserId,
        credentialId: 'cred-$testUserId',
        email: testEmail,
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Developer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      );

      setUp(() {
        authRepository.setUserProfile(testUser);
      });

      test('createUserProfile should create and return profile on success', () async {
        final result = await authManager.createUserProfile(testUser);

        expect(result.isSuccess, true);
        expect(result.data!.credentialId, testUser.credentialId);
        expect(result.data!.email, testUser.email);
        expect(result.data!.firstName, testUser.firstName);
        expect(result.data!.lastName, testUser.lastName);
        expect(result.data!.professionalRole, testUser.professionalRole);
        expect(authRepository.createProfileCalls.length, 1);
      });

      test('createUserProfile should return error on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Failed to create profile',
          errorType: AuthErrorType.serverError,
        );

        final result = await authManager.createUserProfile(testUser);

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
        expect(authRepository.createProfileCalls.length, 0);
        expect(authNotifier.userProfileChangedEvents.isEmpty, true);
      });

      test('getUserProfile should return user profile by credentialId', () async {
        authRepository.setUserProfile(testUser);
        final result = await authManager.getUserProfile(testUser.credentialId);

        expect(result.isSuccess, true);
        expect(result.data!.id, testUser.id);
        expect(authRepository.getUserProfileCalls.length, 1);
      });

      test('getUserProfile should return error on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Failed to get profile',
          errorType: AuthErrorType.serverError,
        );

        final result = await authManager.getUserProfile(testUserId);

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
        expect(authRepository.getUserProfileCalls.length, 0);
        expect(authNotifier.userProfileChangedEvents.isEmpty, true);
      });

      test('updateUserProfile should update and return profile on success', () async {
        final result = await authManager.updateUserProfile(testUser);

        expect(result.isSuccess, true);
        expect(result.data!.credentialId, testUser.credentialId);
        expect(result.data!.email, testUser.email);
        expect(result.data!.firstName, testUser.firstName);
        expect(result.data!.lastName, testUser.lastName);
        expect(result.data!.professionalRole, testUser.professionalRole);
        expect(authRepository.updateProfileCalls.length, 1);
      });

      test('updateUserProfile should return error on failure', () async {
        authManager.setAuthResponse(
          succeed: false,
          errorMessage: 'Failed to update profile',
          errorType: AuthErrorType.serverError,
        );

        final result = await authManager.updateUserProfile(testUser);

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
        expect(authRepository.updateProfileCalls.length, 0);
        expect(authNotifier.userProfileChangedEvents.isEmpty, true);
      });
    });

    test('reset should clear all tracking and state', () async {
      await authManager.loginWithEmail(testEmail, testPassword);
      await authManager.sendOtp(testEmail, OtpReceiver.email);
      await authManager.resetPassword(testEmail);
      authNotifier.stateChangedEvents.clear();

      authManager.reset();

      expect(authManager.loginAttempts, isEmpty);
      expect(authManager.registrationAttempts, isEmpty);
      expect(authManager.otpSendAttempts, isEmpty);
      expect(authManager.otpVerificationAttempts, isEmpty);
      expect(authManager.passwordResetAttempts, isEmpty);
      expect(authManager.emailCheckAttempts, isEmpty);
      expect(authManager.logoutAttempts, isEmpty);
      expect(authManager.isAuthenticated(), false);
      expect(authManager.getCurrentCredentials().data, null);
    });
  });
}

class _TestAppModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<AuthNotifierController>(() => FakeAuthNotifier());
    i.addSingleton<AuthRepository>(() => FakeAuthRepository());
    i.add<AuthManager>(() => FakeAuthManager(
      authNotifier: i(),
      authRepository: i(),
    ));
  }
}