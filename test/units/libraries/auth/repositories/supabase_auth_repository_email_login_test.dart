import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseAuthRepository authRepository;

  setUp(() {
    fakeSupabaseWrapper = FakeSupabaseWrapper();
    authRepository = SupabaseAuthRepository(supabaseWrapper: fakeSupabaseWrapper);
  });

  tearDown(() {
    // Ensure resources are cleaned up after each test.
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
  });

  group('Email and Password Login', () {
    test(
      'should successfully log in existing user with valid credentials',
      () async {
        const userEmail = 'john.doe@construction.com';
        const userPassword = 'SecurePass123!';

        final result = await authRepository.loginWithEmail(
          userEmail,
          userPassword,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.email, equals(userEmail));
        expect(result.data?.id, isNotNull);
        expect(result.errorMessage, isNull);

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'signInWithPassword',
        );
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first['email'], equals(userEmail));
        expect(methodCalls.first['password'], equals(userPassword));
      },
    );

    test('should reject login with incorrect password', () async {
      fakeSupabaseWrapper.shouldThrowOnSignIn = true;
      fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
      fakeSupabaseWrapper.signInErrorMessage = 'invalid_credentials';

      final result = await authRepository.loginWithEmail(
        'user@example.com',
        'wrongpassword',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.invalidCredentials));
      expect(result.errorMessage, contains('Invalid email or password'));
    });

    test(
      'should handle account lockout due to too many failed attempts',
      () async {
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
        fakeSupabaseWrapper.signInErrorMessage = 'over_request_rate_limit';

        final result = await authRepository.loginWithEmail(
          'user@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.rateLimited));
        expect(result.errorMessage, contains('Too many attempts'));
      },
    );

    test(
      'should handle network connectivity issues during login',
      () async {
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.socket;
        fakeSupabaseWrapper.signInErrorMessage = 'Network unreachable';

        final result = await authRepository.loginWithEmail(
          'user@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.networkError));
        expect(result.errorMessage, contains('Network connection failed'));
      },
    );

    test('should handle server timeout during authentication', () async {
      fakeSupabaseWrapper.shouldThrowOnSignIn = true;
      fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.unknown;
      fakeSupabaseWrapper.signInErrorMessage = 'Request timeout';

      final result = await authRepository.loginWithEmail(
        'user@example.com',
        'password',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.timeout));
      expect(result.errorMessage, contains('Request timed out'));
    });

    test('should handle malformed authentication response', () async {
      fakeSupabaseWrapper.shouldThrowOnSignIn = true;
      fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.unknown;

      final result = await authRepository.loginWithEmail(
        'user@example.com',
        'password',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test(
      'should handle authentication service returning null user',
      () async {
        fakeSupabaseWrapper.shouldReturnNullUser = true;

        final result = await authRepository.loginWithEmail(
          'user@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.invalidCredentials));
        expect(
          result.errorMessage,
          contains('Login failed - invalid credentials'),
        );
      },
    );

    test('should handle various authentication error patterns', () async {
      // Test different Supabase error scenarios that might occur in production
      final errorScenarios = [
        {
          'message': 'invalid_credentials',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {
          'message': 'user_not_found',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {
          'message': 'email_address_invalid',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {
          'message': 'weak_password',
          'expectedType': AuthErrorType.invalidCredentials,
        },
        {
          'message': 'email_not_confirmed',
          'expectedType': AuthErrorType.invalidCredentials,
        },
      ];

      for (final scenario in errorScenarios) {
        fakeSupabaseWrapper.reset();
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
        fakeSupabaseWrapper.signInErrorMessage =
            scenario['message'] as String;

        final result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );

        expect(
          result.isSuccess,
          isFalse,
          reason: 'Should fail for: ${scenario['message']}',
        );
        expect(
          result.errorType,
          equals(scenario['expectedType']),
          reason: 'Error type should match for: ${scenario['message']}',
        );
      }
    });
  });
} 