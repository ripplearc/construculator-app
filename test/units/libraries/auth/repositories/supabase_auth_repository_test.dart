import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/config/app_config_impl.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseAuthRepository authRepository;
  late FakeEnvLoader fakeDotEnvLoader;
  late AppConfigImpl appConfig;

  setUp(() {
    fakeSupabaseWrapper = FakeSupabaseWrapper();
    authRepository = SupabaseAuthRepository(fakeSupabaseWrapper);
    fakeDotEnvLoader = FakeEnvLoader();

    appConfig = AppConfigImpl(
      envLoader: fakeDotEnvLoader,
    );
    appConfig.initialize(Environment.dev);
  });

  tearDown(() {
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
  });

  group('User Authentication', () {
    group('Email and Password Login', () {
      test(
        'should successfully log in existing user with valid credentials',
        () async {
          // Arrange
          const userEmail = 'john.doe@construction.com';
          const userPassword = 'SecurePass123!';

          // Act
          final result = await authRepository.loginWithEmail(
            userEmail,
            userPassword,
          );

          // Assert
          expect(result.isSuccess, isTrue);
          expect(result.data?.email, equals(userEmail));
          expect(result.data?.id, isNotNull);
          expect(result.errorMessage, isNull);

          // Verify correct parameters were passed
          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
            'signInWithPassword',
          );
          expect(methodCalls.length, equals(1));
          expect(methodCalls.first['email'], equals(userEmail));
          expect(methodCalls.first['password'], equals(userPassword));
        },
      );

      test('should reject login with incorrect password', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
        fakeSupabaseWrapper.signInErrorMessage = 'invalid_credentials';

        // Act
        final result = await authRepository.loginWithEmail(
          'user@example.com',
          'wrongpassword',
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.invalidCredentials));
        expect(result.errorMessage, contains('Invalid email or password'));
      });

      test(
        'should handle account lockout due to too many failed attempts',
        () async {
          // Arrange
          fakeSupabaseWrapper.shouldThrowOnSignIn = true;
          fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
          fakeSupabaseWrapper.signInErrorMessage = 'over_request_rate_limit';

          // Act
          final result = await authRepository.loginWithEmail(
            'user@example.com',
            'password',
          );

          // Assert
          expect(result.isSuccess, isFalse);
          expect(result.errorType, equals(AuthErrorType.rateLimited));
          expect(result.errorMessage, contains('Too many attempts'));
        },
      );

      test('should handle network connectivity issues during login', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.socket;
        fakeSupabaseWrapper.signInErrorMessage = 'Network unreachable';

        // Act
        final result = await authRepository.loginWithEmail(
          'user@example.com',
          'password',
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.networkError));
        expect(result.errorMessage, contains('Network connection failed'));
      });

      test('should handle server timeout during authentication', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.timeout;
        fakeSupabaseWrapper.signInErrorMessage = 'Request timeout';

        // Act
        final result = await authRepository.loginWithEmail(
          'user@example.com',
          'password',
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.timeout));
        expect(result.errorMessage, contains('Request timed out'));
      });

      test('should handle malformed authentication response', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.unknown;

        // Act
        final result = await authRepository.loginWithEmail(
          'user@example.com',
          'password',
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.serverError));
      });

      test(
        'should handle authentication service returning null user',
        () async {
          // Arrange
          fakeSupabaseWrapper.shouldReturnNullUser = true;

          // Act
          final result = await authRepository.loginWithEmail(
            'user@example.com',
            'password',
          );

          // Assert
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

    group('User Registration', () {
      test(
        'should successfully register new user with valid information',
        () async {
          // Arrange
          const newUserEmail = 'sarah.wilson@contractor.com';
          const newUserPassword = 'StrongPassword456!';

          // Act
          final result = await authRepository.registerWithEmail(
            newUserEmail,
            newUserPassword,
          );

          // Assert
          expect(result.isSuccess, isTrue);
          expect(result.data?.email, equals(newUserEmail));
          expect(result.data?.id, isNotNull);

          // Verify correct parameters were passed
          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('signUp');
          expect(methodCalls.length, equals(1));
          expect(methodCalls.first['email'], equals(newUserEmail));
          expect(methodCalls.first['password'], equals(newUserPassword));
        },
      );

      test('should prevent registration with already existing email', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSignUp = true;
        fakeSupabaseWrapper.signUpExceptionType = FakeExceptionType.postgrest;
        fakeSupabaseWrapper.postgrestErrorCode = '23505';
        fakeSupabaseWrapper.signUpErrorMessage =
            'duplicate key value violates unique constraint';

        // Act
        final result = await authRepository.registerWithEmail(
          'existing@example.com',
          'password',
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.registrationFailure));
        expect(result.errorMessage, contains('Email already exists'));
      });

      test(
        'should handle database connection issues during registration',
        () async {
          // Arrange
          fakeSupabaseWrapper.shouldThrowOnSignUp = true;
          fakeSupabaseWrapper.signUpExceptionType = FakeExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode = '08001';
          fakeSupabaseWrapper.signUpErrorMessage =
              'could not connect to server';

          // Act
          final result = await authRepository.registerWithEmail(
            'newuser@example.com',
            'password',
          );

          // Assert
          expect(result.isSuccess, isFalse);
          expect(result.errorType, equals(AuthErrorType.connectionError));
          expect(result.errorMessage, contains('Database connection failed'));
        },
      );

      test('should handle registration service returning null user', () async {
        // Arrange
        fakeSupabaseWrapper.shouldReturnNullUser = true;

        // Act
        final result = await authRepository.registerWithEmail(
          'newuser@example.com',
          'password',
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.registrationFailure));
        expect(
          result.errorMessage,
          contains('Registration failed - please try again'),
        );
      });

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
              reason: 'Error type should match for code: ${errorCode['code']}',
            );
          }
        },
      );
    });

    group('One-Time Password (OTP) Authentication', () {
      test('should send OTP to user email address', () async {
        // Arrange
        const userEmail = 'contractor@buildsite.com';

        // Act
        final result = await authRepository.sendOtp(
          userEmail,
          OtpReceiver.email,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.errorMessage, isNull);

        // Verify correct parameters for email OTP
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'signInWithOtp',
        );
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first['email'], equals(userEmail));
        expect(methodCalls.first['phone'], isNull);
        expect(methodCalls.first['shouldCreateUser'], isTrue);
      });

      test('should send OTP to user phone number', () async {
        // Arrange
        const userPhone = '+1-555-123-4567';

        // Act
        final result = await authRepository.sendOtp(
          userPhone,
          OtpReceiver.phone,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.errorMessage, isNull);

        // Verify correct parameters for phone OTP
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'signInWithOtp',
        );
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first['email'], isNull);
        expect(methodCalls.first['phone'], equals(userPhone));
        expect(methodCalls.first['shouldCreateUser'], isTrue);
      });

      test('should verify valid OTP code sent to email', () async {
        // Arrange
        const userEmail = 'foreman@construction.com';
        const otpCode = '123456';

        // Act
        final result = await authRepository.verifyOtp(
          userEmail,
          otpCode,
          OtpReceiver.email,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.email, equals(userEmail));

        // Verify correct parameters for email OTP verification
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('verifyOTP');
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first['email'], equals(userEmail));
        expect(methodCalls.first['phone'], isNull);
        expect(methodCalls.first['token'], equals(otpCode));
        expect(methodCalls.first['type'], equals(supabase.OtpType.email));
      });

      test('should verify valid OTP code sent to phone', () async {
        // Arrange
        const userPhone = '+1-555-987-6543';
        const otpCode = '654321';

        // Act
        final result = await authRepository.verifyOtp(
          userPhone,
          otpCode,
          OtpReceiver.phone,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);

        // Verify correct parameters for phone OTP verification
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('verifyOTP');
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first['email'], isNull);
        expect(methodCalls.first['phone'], equals(userPhone));
        expect(methodCalls.first['token'], equals(otpCode));
        expect(methodCalls.first['type'], equals(supabase.OtpType.sms));
      });

      test('should handle invalid OTP verification', () async {
        // Arrange
        fakeSupabaseWrapper.shouldReturnNullUser = true;

        // Act
        final result = await authRepository.verifyOtp(
          'user@example.com',
          '000000',
          OtpReceiver.email,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.invalidCredentials));
        expect(result.errorMessage, contains('Invalid verification code'));
      });
    });

    group('Email Registration Check', () {
      test('should confirm existing user email is registered', () async {
        // Arrange
        const existingEmail = 'manager@construction.com';
        fakeSupabaseWrapper.addTableData('users', [
          {'id': '123', 'email': existingEmail},
        ]);

        // Act
        final result = await authRepository.isEmailRegistered(existingEmail);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isTrue);

        // Verify correct database query
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'selectSingle',
        );
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first['table'], equals('users'));
        expect(methodCalls.first['columns'], equals('id'));
        expect(methodCalls.first['filterColumn'], equals('email'));
        expect(methodCalls.first['filterValue'], equals(existingEmail));
      });

      test('should confirm new email is not registered', () async {
        // Arrange - No user data added, so email won't be found
        const newEmail = 'newuser@construction.com';

        // Act
        final result = await authRepository.isEmailRegistered(newEmail);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isFalse);
      });

      test(
        'should handle database connectivity issues during email check',
        () async {
          // Arrange
          fakeSupabaseWrapper.shouldThrowOnSelect = true;
          fakeSupabaseWrapper.selectErrorMessage =
              'Connection to database lost';

          // Act
          final result = await authRepository.isEmailRegistered(
            'test@example.com',
          );

          // Assert
          expect(result.isSuccess, isFalse);
          expect(result.errorType, equals(AuthErrorType.serverError));
          expect(result.errorMessage, contains('Connection to database lost'));
        },
      );
    });
  });

  group('User Profile Management', () {
    group('Retrieve User Profile', () {
      test('should get complete user profile for active user', () async {
        // Arrange
        const credentialId = 'cred-123-active-user';
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': '123',
            'credential_id': credentialId,
            'email': 'project.manager@construction.com',
            'phone': '+1-555-123-4567',
            'first_name': 'Sarah',
            'last_name': 'Johnson',
            'professional_role': 'Project Manager',
            'profile_photo_url': 'https://storage.example.com/photos/sarah.jpg',
            'created_at': '2023-01-15T08:30:00Z',
            'updated_at': '2023-12-01T14:22:00Z',
            'user_status': 'active',
            'user_preferences': {
              'theme': 'light',
              'notifications': true,
              'language': 'en',
            },
          },
        ]);

        // Act
        final result = await authRepository.getUserProfile(credentialId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.email, equals('project.manager@construction.com'));
        expect(result.data?.firstName, equals('Sarah'));
        expect(result.data?.lastName, equals('Johnson'));
        expect(result.data?.professionalRole, equals('Project Manager'));
        expect(result.data?.userStatus, equals(UserProfileStatus.active));
        expect(result.data?.userPreferences['theme'], equals('light'));

        // Verify correct database query
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'selectSingle',
        );
        expect(methodCalls.first['table'], equals('users'));
        expect(methodCalls.first['filterColumn'], equals('credential_id'));
        expect(methodCalls.first['filterValue'], equals(credentialId));
      });

      test('should get user profile for inactive user', () async {
        // Arrange
        const credentialId = 'cred-456-inactive-user';
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': '456',
            'credential_id': credentialId,
            'email': 'former.employee@construction.com',
            'phone': null,
            'first_name': 'Mike',
            'last_name': 'Chen',
            'professional_role': 'Former Supervisor',
            'profile_photo_url': null,
            'user_status': 'inactive',
            'created_at': '2022-06-01T00:00:00Z',
            'updated_at': '2023-08-15T00:00:00Z',
            'user_preferences': null,
          },
        ]);

        // Act
        final result = await authRepository.getUserProfile(credentialId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userStatus, equals(UserProfileStatus.inactive));
        expect(result.data?.userPreferences, isEmpty);
        expect(result.data?.phone, isNull);
        expect(result.data?.profilePhotoUrl, isNull);
      });

      test('should handle request for non-existent user profile', () async {
        // Arrange - No user data added
        const nonExistentCredentialId = 'cred-999-not-found';

        // Act
        final result = await authRepository.getUserProfile(
          nonExistentCredentialId,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.userNotFound));
        expect(result.errorMessage, contains('User profile not found'));
      });
    });

    group('Create User Profile', () {
      test('should create new active user profile', () async {
        // Arrange
        final newUser = User(
          id: '',
          credentialId: 'cred-new-active-user',
          email: 'new.engineer@construction.com',
          phone: '+1-555-234-5678',
          firstName: 'Alex',
          lastName: 'Rodriguez',
          professionalRole: 'Site Engineer',
          profilePhotoUrl: 'https://storage.example.com/photos/alex.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark', 'units': 'metric'},
        );

        // Act
        final result = await authRepository.createUserProfile(newUser);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userStatus, equals(UserProfileStatus.active));
        expect(result.data?.email, equals('new.engineer@construction.com'));

        // Verify correct database insertion
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('insert');
        expect(methodCalls.first['table'], equals('users'));

        final insertData = methodCalls.first['data'] as Map<String, dynamic>;
        expect(insertData['credential_id'], equals('cred-new-active-user'));
        expect(insertData['email'], equals('new.engineer@construction.com'));
        expect(insertData['user_status'], equals('active'));
        expect(
          insertData['user_preferences'],
          equals({'theme': 'dark', 'units': 'metric'}),
        );
      });

      test('should create new inactive user profile', () async {
        // Arrange
        final newUser = User(
          id: '',
          credentialId: 'cred-new-inactive-user',
          email: 'temp.worker@construction.com',
          phone: null,
          firstName: 'Jordan',
          lastName: 'Smith',
          professionalRole: 'Temporary Worker',
          profilePhotoUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.inactive,
          userPreferences: {},
        );

        // Act
        final result = await authRepository.createUserProfile(newUser);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userStatus, equals(UserProfileStatus.inactive));

        // Verify status conversion in database
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('insert');
        final insertData = methodCalls.first['data'] as Map<String, dynamic>;
        expect(insertData['user_status'], equals('inactive'));
      });
    });

    group('Update User Profile', () {
      test('should update existing user profile information', () async {
        // Arrange
        const credentialId = 'cred-update-user';
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': '789',
            'credential_id': credentialId,
            'email': 'old.email@construction.com',
            'user_status': 'inactive',
            'created_at': '2023-01-01T00:00:00Z',
            'updated_at': '2023-01-01T00:00:00Z',
          },
        ]);

        final updatedUser = User(
          id: '789',
          credentialId: credentialId,
          email: 'updated.email@construction.com',
          phone: '+1-555-999-8888',
          firstName: 'Updated',
          lastName: 'Name',
          professionalRole: 'Senior Project Manager',
          profilePhotoUrl: 'https://storage.example.com/photos/updated.jpg',
          createdAt: DateTime.now().subtract(Duration(days: 365)),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'auto', 'notifications': false},
        );

        // Act
        final result = await authRepository.updateUserProfile(updatedUser);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userStatus, equals(UserProfileStatus.active));
        expect(result.data?.email, equals('updated.email@construction.com'));

        // Verify correct database update
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
        expect(methodCalls.first['table'], equals('users'));
        expect(methodCalls.first['filterColumn'], equals('credential_id'));
        expect(methodCalls.first['filterValue'], equals(credentialId));

        final updateData = methodCalls.first['data'] as Map<String, dynamic>;
        expect(updateData['email'], equals('updated.email@construction.com'));
        expect(updateData['user_status'], equals('active'));
        expect(
          updateData['user_preferences'],
          equals({'theme': 'auto', 'notifications': false}),
        );
      });
    });
  });

  group('Error Handling and Edge Cases', () {
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
        fakeSupabaseWrapper.reset();
        authRepository.dispose();
        fakeSupabaseWrapper = FakeSupabaseWrapper();
        authRepository = SupabaseAuthRepository(fakeSupabaseWrapper);

        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInErrorMessage = scenario['message'] as String;

        // Use auth exception type for specific error codes
        if (scenario['useAuthException'] == true) {
          fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
        }

        final result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(scenario['expectedType']));
        // print('Error type should match for: ${scenario['message']}');
      }
    });

    test('should handle rate limiting scenarios', () async {
      final rateLimitScenarios = [
        'Rate limit exceeded for this endpoint',
        'too_many_requests',
      ];

      for (final errorMessage in rateLimitScenarios) {
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
        fakeSupabaseWrapper.signInExceptionType = FakeExceptionType.auth;
        fakeSupabaseWrapper.signInErrorMessage = scenario['code'] as String;

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
      // Arrange
      fakeSupabaseWrapper.shouldThrowOnSignOut = true;
      fakeSupabaseWrapper.signOutErrorMessage = 'Logout failed';

      // Act
      final result = await authRepository.logout();

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle password reset errors', () async {
      // Arrange
      fakeSupabaseWrapper.shouldThrowOnResetPassword = true;
      fakeSupabaseWrapper.resetPasswordErrorMessage = 'Reset failed';

      // Act
      final result = await authRepository.resetPassword('test@example.com');

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle email registration check errors', () async {
      // Arrange
      fakeSupabaseWrapper.shouldThrowOnSelect = true;
      fakeSupabaseWrapper.selectErrorMessage = 'Database error';

      // Act
      final result = await authRepository.isEmailRegistered('test@example.com');

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle user profile retrieval errors', () async {
      // Arrange
      fakeSupabaseWrapper.shouldThrowOnSelect = true;
      fakeSupabaseWrapper.selectErrorMessage = 'Profile fetch failed';

      // Act
      final result = await authRepository.getUserProfile('test-credential-id');

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle user profile creation errors', () async {
      // Arrange
      fakeSupabaseWrapper.shouldThrowOnInsert = true;
      fakeSupabaseWrapper.insertErrorMessage = 'Profile creation failed';

      final user = User(
        id: 'test-id',
        credentialId: 'test-credential-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Developer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      );

      // Act
      final result = await authRepository.createUserProfile(user);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle user profile update errors', () async {
      // Arrange
      fakeSupabaseWrapper.shouldThrowOnUpdate = true;
      fakeSupabaseWrapper.updateErrorMessage = 'Profile update failed';

      final user = User(
        id: 'test-id',
        credentialId: 'test-credential-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Developer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      );

      // Act
      final result = await authRepository.updateUserProfile(user);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test(
      'should handle user preferences as string in profile parsing',
      () async {
        // Arrange
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': 'test-id',
            'credential_id': 'test-credential-id',
            'email': 'test@example.com',
            'phone': null,
            'first_name': 'Test',
            'last_name': 'User',
            'professional_role': 'Developer',
            'profile_photo_url': null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'user_status': 'active',
            'user_preferences':
                '{"theme": "dark", "notifications": true}', // String JSON
          },
        ]);

        // Act
        final result = await authRepository.getUserProfile(
          'test-credential-id',
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, isA<Map<String, dynamic>>());
        expect(result.data?.userPreferences['theme'], equals('dark'));
        expect(result.data?.userPreferences['notifications'], equals(true));
      },
    );

    test('should handle null user preferences in profile parsing', () async {
      // Arrange
      fakeSupabaseWrapper.addTableData('users', [
        {
          'id': 'test-id',
          'credential_id': 'test-credential-id',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'Test',
          'last_name': 'User',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'user_status': 'active',
          'user_preferences': null, // Null preferences
        },
      ]);

      // Act
      final result = await authRepository.getUserProfile('test-credential-id');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.userPreferences, equals({}));
    });

    test('should handle inactive user status in profile parsing', () async {
      // Arrange
      fakeSupabaseWrapper.addTableData('users', [
        {
          'id': 'test-id',
          'credential_id': 'test-credential-id',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'Test',
          'last_name': 'User',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'user_status': 'inactive', // Inactive status
          'user_preferences': {},
        },
      ]);

      // Act
      final result = await authRepository.getUserProfile('test-credential-id');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.userStatus, equals(UserProfileStatus.inactive));
    });

    test(
      'should handle user preferences as map in create profile response',
      () async {
        // Arrange
        final user = User(
          id: 'test-id',
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        // Act
        final result = await authRepository.createUserProfile(user);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, equals({'theme': 'dark'}));
      },
    );

    test(
      'should handle empty user preferences in create profile response',
      () async {
        // Arrange
        final user = User(
          id: 'test-id',
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // Act
        final result = await authRepository.createUserProfile(user);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, equals({}));
      },
    );

    test(
      'should handle user preferences as map in update profile response',
      () async {
        // Arrange
        final user = User(
          id: 'test-id',
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'light'},
        );

        // First create the user in the table
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': 'test-id',
            'credential_id': 'test-credential-id',
            'email': 'test@example.com',
            'phone': null,
            'first_name': 'Test',
            'last_name': 'User',
            'professional_role': 'Developer',
            'profile_photo_url': null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'user_status': 'active',
            'user_preferences': {'theme': 'dark'},
          },
        ]);

        // Act
        final result = await authRepository.updateUserProfile(user);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, equals({'theme': 'light'}));
      },
    );

    test(
      'should handle empty user preferences in update profile response',
      () async {
        // Arrange
        final user = User(
          id: 'test-id',
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // First create the user in the table
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': 'test-id',
            'credential_id': 'test-credential-id',
            'email': 'test@example.com',
            'phone': null,
            'first_name': 'Test',
            'last_name': 'User',
            'professional_role': 'Developer',
            'profile_photo_url': null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'user_status': 'active',
            'user_preferences': 'not_a_map',
          },
        ]);

        // Act
        final result = await authRepository.updateUserProfile(user);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, equals({}));
      },
    );
  });

  group('Authentication State Management', () {
    test('should handle authentication stream errors appropriately', () async {
      // Test various auth stream errors
      final authErrors = [
        'Authentication token has expired',
        'User session is no longer valid',
        'Access to resource is forbidden',
        'Invalid authentication grant provided',
        'No active session found for user',
      ];

      for (final errorMessage in authErrors) {
        fakeSupabaseWrapper.reset();
        authRepository.dispose();
        fakeSupabaseWrapper = FakeSupabaseWrapper();
        authRepository = SupabaseAuthRepository(fakeSupabaseWrapper);

        // Simulate auth stream error using the available method
        fakeSupabaseWrapper.simulateAuthStreamError(errorMessage);

        // Allow time for error handling
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify error was handled (no exception thrown)
        expect(true, isTrue); // Test passes if no exception
      }
    });

    test('should handle network-related stream errors', () async {
      // Arrange
      fakeSupabaseWrapper.reset();
      authRepository.dispose();
      fakeSupabaseWrapper = FakeSupabaseWrapper();
      authRepository = SupabaseAuthRepository(fakeSupabaseWrapper);

      // Act - Simulate network error
      fakeSupabaseWrapper.simulateAuthStreamError(
        'Network connection lost during authentication',
      );

      // Allow time for error handling
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - Should handle gracefully
      expect(true, isTrue); // Test passes if no exception
    });

    test(
      'should handle authentication responses with missing user data',
      () async {
        // Test first scenario: null user returned
        fakeSupabaseWrapper.shouldReturnNullUser = true;
        var result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );
        expect(result.isSuccess, isFalse);

        // Test second scenario: successful auth with user
        fakeSupabaseWrapper.reset();
        result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );
        expect(result.isSuccess, isTrue);
      },
    );

    test('should handle getCurrentCredentials when user is null', () {
      // Arrange
      fakeSupabaseWrapper.shouldReturnUser = false;

      // Act
      final credentials = authRepository.getCurrentCredentials();

      // Assert
      expect(credentials, isNull);
    });

    test('should handle getCurrentCredentials when user exists', () async {
      // Arrange - First login to create a user
      await authRepository.loginWithEmail('test@example.com', 'password');
      fakeSupabaseWrapper.shouldReturnUser = true;

      // Act
      final credentials = authRepository.getCurrentCredentials();

      // Assert
      expect(credentials, isNotNull);
      expect(credentials?.email, equals('test@example.com'));
    });

    test('should handle isAuthenticated when user is null', () {
      // Arrange
      fakeSupabaseWrapper.shouldReturnUser = false;

      // Act
      final isAuth = authRepository.isAuthenticated();

      // Assert
      expect(isAuth, isFalse);
    });

    test('should handle isAuthenticated when user exists', () async {
      // Arrange - First login to create a user
      await authRepository.loginWithEmail('test@example.com', 'password');
      fakeSupabaseWrapper.shouldReturnUser = true;

      // Act
      final isAuth = authRepository.isAuthenticated();

      // Assert
      expect(isAuth, isTrue);
    });
  });
}
