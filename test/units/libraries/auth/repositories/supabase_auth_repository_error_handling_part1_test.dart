import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseAuthRepository authRepository;

  setUp(() {
    fakeSupabaseWrapper = FakeSupabaseWrapper();
    authRepository = SupabaseAuthRepository(supabaseWrapper: fakeSupabaseWrapper);
  });

  tearDown(() {
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
  });

  group('Error Handling and Edge Cases Part 1', () {
    test('should handle various authentication error scenarios', () async {
      final errorScenarios = [
        {
          'message': 'Login credentials are not valid',
          'expectedType': AuthErrorType.serverError,
        },
        {
          'message': 'invalid_credentials',
          'expectedType': AuthErrorType.invalidCredentials,
          'useAuthException': true,
        },
        {
          'message': 'Email address format is incorrect',
          'expectedType': AuthErrorType.serverError,
        },
        {
          'message': 'Password does not meet security requirements',
          'expectedType': AuthErrorType.serverError,
        },
        {
          'message': 'User authentication token has expired',
          'expectedType': AuthErrorType.serverError,
        },
      ];

      for (final scenario in errorScenarios) {
        // Resetting parts of the test environment for this specific looped test.
        // The main authRepository is setup per test via setUp/tearDown.
        // This local reset ensures each scenario iteration has a fresh fake wrapper.
        var localFakeSupabaseWrapper = FakeSupabaseWrapper();
        var localAuthRepository = SupabaseAuthRepository(
          supabaseWrapper: localFakeSupabaseWrapper,
        );

        localFakeSupabaseWrapper.shouldThrowOnSignIn = true;
        localFakeSupabaseWrapper.signInErrorMessage =
            scenario['message'] as String;

        if (scenario['useAuthException'] == true) {
          localFakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
        }

        final result = await localAuthRepository.loginWithEmail(
          'test@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(scenario['expectedType']));
        
        localAuthRepository.dispose(); // Clean up local instance
      }
    });

    test('should handle rate limiting scenarios', () async {
      final rateLimitScenarios = [
        'Rate limit exceeded for this endpoint',
        'too_many_requests',
      ];

      for (final errorMessage in rateLimitScenarios) {
        fakeSupabaseWrapper.reset(); // Uses the file-level fakeSupabaseWrapper
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.unknown;
        fakeSupabaseWrapper.signInErrorMessage = errorMessage;

        final result = await authRepository.loginWithEmail( // Uses the file-level authRepository
          'test@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.serverError));
      }
    });

    test('should handle network connectivity error patterns', () async {
      final networkErrors = [
        'Network connection failed during request',
        'Connection to authentication server failed',
      ];

      for (final errorMessage in networkErrors) {
        fakeSupabaseWrapper.reset();
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.unknown;
        fakeSupabaseWrapper.signInErrorMessage = errorMessage;

        final result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.serverError));
      }
    });

    test('should handle auth exception error codes', () async {
      final authErrorCodes = [
        {
          'code': 'email_exists',
          'expectedType': AuthErrorType.registrationFailure,
        },
        {
          'code': 'user_already_exists',
          'expectedType': AuthErrorType.registrationFailure,
        },
        {
          'code': 'over_email_send_rate_limit',
          'expectedType': AuthErrorType.rateLimited,
        },
        {
          'code': 'over_sms_send_rate_limit',
          'expectedType': AuthErrorType.rateLimited,
        },
        {
          'code': 'signup_disabled',
          'expectedType': AuthErrorType.registrationFailure,
        },
        {
          'code': 'email_provider_disabled',
          'expectedType': AuthErrorType.registrationFailure,
        },
        {
          'code': 'phone_provider_disabled',
          'expectedType': AuthErrorType.registrationFailure,
        },
        {
          'code': 'session_expired',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {
          'code': 'session_not_found',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {
          'code': 'refresh_token_not_found',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {
          'code': 'refresh_token_already_used',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {'code': 'request_timeout', 'expectedType': AuthErrorType.timeout},
        {
          'code': 'otp_expired',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {'code': 'bad_jwt', 'expectedType': AuthErrorType.invalidCredentials},
        {
          'code': 'no_authorization',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {
          'code': 'unknown_error_code',
          'expectedType': AuthErrorType.invalidCredentials,
        },
      ];

      for (final scenario in authErrorCodes) {
        fakeSupabaseWrapper.reset();
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
<<<<<<< HEAD
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
        fakeSupabaseWrapper.signInErrorMessage = scenario['code'] as String;
=======
        fakeSupabaseWrapper.signInExceptionType = 'auth';
        fakeSupabaseWrapper.signInErrorCode = scenario['code'] as String;
>>>>>>> 1b91bce (Add more test scenarios)

        final result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );

        expect(
          result.isSuccess,
          isFalse,
          reason: 'Should fail for: ${scenario['code']}',
        );
        expect(
          result.errorType,
          equals(scenario['expectedType']),
          reason: 'Error type should match for: ${scenario['code']}',
        );
      }
    });

    test('should handle postgrest exception error codes', () async {
      final postgrestErrorCodes = [
        {'code': '08001', 'expectedType': AuthErrorType.connectionError},
        {'code': '08006', 'expectedType': AuthErrorType.connectionError},
        {'code': '08003', 'expectedType': AuthErrorType.connectionError},
        {'code': '99999', 'expectedType': AuthErrorType.serverError},
      ];

      for (final scenario in postgrestErrorCodes) {
        fakeSupabaseWrapper.reset();
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.postgrest;
        fakeSupabaseWrapper.postgrestErrorCode = scenario['code'] as String;

        final result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );

        expect(
          result.isSuccess,
          isFalse,
          reason: 'Should fail for: ${scenario['code']}',
        );
        expect(
          result.errorType,
          equals(scenario['expectedType']),
          reason: 'Error type should match for: ${scenario['code']}',
        );
      }
    });

    test('should handle logout errors', () async {
      fakeSupabaseWrapper.shouldThrowOnSignOut = true;
      fakeSupabaseWrapper.signOutErrorMessage = 'Logout failed';

      final result = await authRepository.logout();

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle password reset errors', () async {
      fakeSupabaseWrapper.shouldThrowOnResetPassword = true;
      fakeSupabaseWrapper.resetPasswordErrorMessage = 'Reset failed';

      final result = await authRepository.resetPassword('test@example.com');

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });
  });

  test(
        'should handle AuthSessionMissingException from auth stream',
        () async {
          // Arrange
          final exception = supabase.AuthSessionMissingException();
          final authStateFuture = expectLater(
            authRepository.authStateChanges,
            emits(AuthStatus.unauthenticated),
          );
          final userFuture = expectLater(
            authRepository.userChanges,
            emits(isNull),
          );

          // Act
          fakeSupabaseWrapper.simulateAuthStreamError('',exception: exception);

          // Assert
          await authStateFuture;
          await userFuture;
        },
      );

      test(
        'should handle generic Exception from auth stream',
        () async {
          // Arrange
          final exception = Exception('Generic stream error');
          // First emits unauthenticated, then emits connection error.
          // By default when auth repo is instantiated and there is no user, it emits unauthenticated.
          final authStateFuture = expectLater(
            authRepository.authStateChanges,
            emitsInOrder([AuthStatus.unauthenticated, AuthStatus.connectionError]),
          );

          // Act
          fakeSupabaseWrapper.simulateAuthStreamError('',exception: exception);

          // Assert
          await authStateFuture;
        },
      );
} 