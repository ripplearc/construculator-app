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

  group('User Registration', () {
    test(
      'should successfully register new user with valid information',
      () async {
        const newUserEmail = 'sarah.wilson@contractor.com';
        const newUserPassword = 'StrongPassword456!';

        final result = await authRepository.registerWithEmail(
          newUserEmail,
          newUserPassword,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.email, equals(newUserEmail));
        expect(result.data?.id, isNotNull);

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('signUp');
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first['email'], equals(newUserEmail));
        expect(methodCalls.first['password'], equals(newUserPassword));
      },
    );

    test(
      'should prevent registration with already existing email',
      () async {
        fakeSupabaseWrapper.shouldThrowOnSignUp = true;
        fakeSupabaseWrapper.signUpExceptionType = FakeExceptionType.postgrest;
        fakeSupabaseWrapper.postgrestErrorCode = '23505';
        fakeSupabaseWrapper.signUpErrorMessage =
            'duplicate key value violates unique constraint';

        final result = await authRepository.registerWithEmail(
          'existing@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.registrationFailure));
        expect(result.errorMessage, contains('Email already exists'));
      },
    );

    test(
      'should handle database connection issues during registration',
      () async {
        fakeSupabaseWrapper.shouldThrowOnSignUp = true;
        fakeSupabaseWrapper.signUpExceptionType = FakeExceptionType.postgrest;
        fakeSupabaseWrapper.postgrestErrorCode = '08001';
        fakeSupabaseWrapper.signUpErrorMessage =
            'could not connect to server';

        final result = await authRepository.registerWithEmail(
          'newuser@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.connectionError));
        expect(result.errorMessage, contains('Database connection failed'));
      },
    );

    test(
      'should handle registration service returning null user',
      () async {
        fakeSupabaseWrapper.shouldReturnNullUser = true;

        final result = await authRepository.registerWithEmail(
          'newuser@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.registrationFailure));
        expect(
          result.errorMessage,
          contains('Registration failed - please try again'),
        );
      },
    );

    test(
      'should handle various database error codes during registration',
      () async {
        // Test different PostgreSQL error codes that might occur
        final errorCodes = [
          {
            'code': '23505',
            'expectedType': AuthErrorType.registrationFailure,
            'description': 'unique constraint violation',
          },
          {
            'code': '08001',
            'expectedType': AuthErrorType.connectionError,
            'description': 'unable to connect',
          },
          {
            'code': '08006',
            'expectedType': AuthErrorType.connectionError,
            'description': 'connection failure',
          },
          {
            'code': '08003',
            'expectedType': AuthErrorType.connectionError,
            'description': 'connection does not exist',
          },
        ];

        for (final errorCode in errorCodes) {
          fakeSupabaseWrapper.reset();
          fakeSupabaseWrapper.shouldThrowOnSignUp = true;
          fakeSupabaseWrapper.signUpExceptionType = FakeExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              errorCode['code'] as String;
          fakeSupabaseWrapper.signUpErrorMessage =
              errorCode['description'] as String;

          final result = await authRepository.registerWithEmail(
            'test@example.com',
            'password',
          );

          expect(
            result.isSuccess,
            isFalse,
            reason: 'Should fail for error code: ${errorCode['code']}',
          );
          expect(
            result.errorType,
            equals(errorCode['expectedType']),
            reason:
                'Error type should match for code: ${errorCode['code']}',
          );
        }
      },
    );
  });
} 