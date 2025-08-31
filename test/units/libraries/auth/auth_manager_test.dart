import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/repositories/supabase_repository_impl.dart';
import 'package:construculator/libraries/auth/auth_manager_impl.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// This test demonstrates the Test Double pattern:
/// - Real AuthManager (Class A)
/// - Real AuthRepository (Class B)
/// - Fake SupabaseWrapper (B's external dependency)
///
/// This tests the real integration between A and B while controlling
/// external dependencies (database, network) via fakes.
void main() {
  late FakeAuthNotifier authNotifier;
  late SupabaseRepositoryImpl
  realAuthRepository; // ✅ REAL repository implementation
  late FakeSupabaseWrapper fakeSupabaseWrapper; // ✅ FAKE external dependency
  late AuthManagerImpl realAuthManager; // ✅ REAL manager implementation
  late Clock clock;

  const testEmail = 'test@example.com';
  const testPassword = '5i2Un@D8Y9!';

  User createTestUser() {
    return User(
      id: 'test-id',
      credentialId: 'test-cred-id',
      email: testEmail,
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'Developer',
      createdAt: clock.now(),
      updatedAt: clock.now(),
      userStatus: UserProfileStatus.active,
      userPreferences: {},
    );
  }

  setUp(() {
    Modular.init(_TestDoubleAppModule());

    // Get the fake external dependency
    fakeSupabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;

    // Get the REAL repository implementation with fake external dependency
    realAuthRepository =
        Modular.get<AuthRepository>() as SupabaseRepositoryImpl;

    // Get the fake notifier (this could also be real if needed)
    authNotifier = Modular.get<AuthNotifierController>() as FakeAuthNotifier;

    // Get the REAL manager implementation
    realAuthManager = Modular.get<AuthManager>() as AuthManagerImpl;

    clock = Modular.get<Clock>();
  });

  tearDown(() {
    Modular.destroy();
  });

  group('AuthManagerImpl with Test Double Pattern', () {
    group('Testing Real Manager + Real Repository Integration', () {
      test('should initialize with authenticated state when user exists', () async {
        // Arrange - Set up fake external data
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: testEmail,
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );

        // Act - Test that the real manager can access the real repository
        // This tests the REAL integration between AuthManager and AuthRepository
        final result = realAuthManager.getCurrentCredentials();

        // Assert - Verify the real integration works
        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);

        // Verify that the real repository was called (B's real logic executed)
        // The real repository should have mapped the fake Supabase user to a credential
      });

      test(
        'loginWithEmail should authenticate and update state on success',
        () async {
          // Arrange - Set up fake external data
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              email: testEmail,
              id: 'test-id',
              createdAt: clock.now().toIso8601String(),
              appMetadata: {},
            ),
          );

          final loginEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) => state.status == AuthStatus.authenticated,
              ),
            ),
          );

          // Act - Use REAL manager with REAL repository
          final result = await realAuthManager.loginWithEmail(
            testEmail,
            testPassword,
          );

          // Assert - Test the real integration
          expect(result.isSuccess, true);
          expect(result.data!.email, testEmail);
          await loginEvent;

          // Verify the real repository was called (B's real logic executed)
          expect(
            fakeSupabaseWrapper.getMethodCallsFor('signInWithPassword').length,
            1,
          );
        },
      );

      test('loginWithEmail should fail when user is not found', () async {
        // Arrange - Configure fake external dependency to return null
        fakeSupabaseWrapper.shouldReturnNullUser = true;

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.loginWithEmail(
          testEmail,
          testPassword,
        );

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test('logout should emit unauthenticated state', () async {
        // Arrange - First login to set up state
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: testEmail,
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );
        await realAuthManager.loginWithEmail(testEmail, testPassword);

        // Act - Test logout
        final logoutEvent = expectLater(
          authNotifier.onAuthStateChanged,
          emits(
            predicate<AuthState>(
              (state) => state.status == AuthStatus.unauthenticated,
            ),
          ),
        );

        final result = await realAuthManager.logout();

        // Assert
        expect(result.isSuccess, true);
        await logoutEvent;
      });

      test('session expiry should emit unauthenticated state', () async {
        // Arrange - First login to set up state
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: testEmail,
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );
        await realAuthManager.loginWithEmail(testEmail, testPassword);

        // Act - Simulate session expiry via fake external dependency
        final expiryEvent = expectLater(
          authNotifier.onAuthStateChanged,
          emits(
            predicate<AuthState>(
              (state) => state.status == AuthStatus.unauthenticated,
            ),
          ),
        );

        fakeSupabaseWrapper.setAuthStreamError(
          'Auth session missing',
          exception: supabase.AuthSessionMissingException(),
        );

        // Assert
        await expiryEvent;
      });

      test('network error should emit connection error state', () async {
        // Arrange - First login to set up state
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: testEmail,
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );
        await realAuthManager.loginWithEmail(testEmail, testPassword);

        // Act - Simulate network error via fake external dependency
        final errorEvent = expectLater(
          authNotifier.onAuthStateChanged,
          emits(
            predicate<AuthState>(
              (state) => state.status == AuthStatus.connectionError,
            ),
          ),
        );

        fakeSupabaseWrapper.setAuthStreamError(
          'Network error',
          exception: supabase.AuthException('Network error'),
        );

        // Assert
        await errorEvent;
      });

      test('should transition through expected auth states', () async {
        // Arrange - Set up expectation for auth state changes
        // Ignore initial unauthenticated baseline and collapse duplicates
        final eventListener = expectLater(
          authNotifier.onAuthStateChanged
              .map((s) => s.status)
              .distinct()
              .skipWhile((s) => s == AuthStatus.unauthenticated),
          emitsInOrder([AuthStatus.authenticated, AuthStatus.unauthenticated]),
        );

        // Act - Test real state transitions
        await realAuthManager.loginWithEmail(testEmail, testPassword);
        await realAuthManager.logout();

        // Assert
        await eventListener;
        final statuses = authNotifier.stateChangedEvents
            .map((s) => s.status)
            .skipWhile((s) => s == AuthStatus.unauthenticated);
        final distinctStatuses = <AuthStatus>[];
        for (final s in statuses) {
          if (distinctStatuses.isEmpty || distinctStatuses.last != s) {
            distinctStatuses.add(s);
          }
        }
        expect(distinctStatuses, [
          AuthStatus.authenticated,
          AuthStatus.unauthenticated,
        ]);
      });
    });

    group('Extended Authentication Operations with Real Components', () {
      test(
        'registerWithEmail should create account and authenticate on success',
        () async {
          // Arrange - Set up fake external data
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              email: testEmail,
              id: 'test-id',
              createdAt: clock.now().toIso8601String(),
              appMetadata: {},
            ),
          );

          final registerEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) => state.status == AuthStatus.authenticated,
              ),
            ),
          );

          // Act - Use REAL manager with REAL repository
          final result = await realAuthManager.registerWithEmail(
            testEmail,
            testPassword,
          );

          // Assert - Test real registration logic
          expect(result.isSuccess, true);
          expect(result.data!.email, testEmail);
          await registerEvent;
          expect(fakeSupabaseWrapper.getMethodCallsFor('signUp').length, 1);
        },
      );

      test('registerWithEmail should handle registration failure', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnSignUp = true;
        fakeSupabaseWrapper.signUpErrorMessage = 'Registration failed';
        fakeSupabaseWrapper.authErrorCode =
            SupabaseAuthErrorCode.registrationFailure;

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.registerWithEmail(
          testEmail,
          testPassword,
        );

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.registrationFailure);
      });

      test('registerWithEmail should fail when user creation fails', () async {
        // Arrange - Configure fake external dependency to return null
        fakeSupabaseWrapper.shouldReturnNullUser = true;

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.registerWithEmail(
          testEmail,
          testPassword,
        );

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.registrationFailure);
      });

      test('sendOtp should successfully send verification code', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.sendOtp(
          testEmail,
          OtpReceiver.email,
        );

        // Assert - Test real OTP logic
        expect(result.isSuccess, true);
        expect(
          fakeSupabaseWrapper.getMethodCallsFor('signInWithOtp').length,
          1,
        );
      });

      test('sendOtp should handle sending failure', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnOtp = true;
        fakeSupabaseWrapper.otpErrorMessage = 'Failed to send OTP';
        fakeSupabaseWrapper.authErrorCode = SupabaseAuthErrorCode.timeout;

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.sendOtp(
          testEmail,
          OtpReceiver.email,
        );

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.timeout);
      });

      test(
        'verifyOtp should authenticate user on successful verification',
        () async {
          // Arrange - Set up fake external data
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              email: testEmail,
              id: 'test-id',
              createdAt: clock.now().toIso8601String(),
              appMetadata: {},
            ),
          );

          final verifyOtpEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) => state.status == AuthStatus.authenticated,
              ),
            ),
          );

          // Act - Use REAL manager with REAL repository
          final result = await realAuthManager.verifyOtp(
            testEmail,
            '123456',
            OtpReceiver.email,
          );

          // Assert - Test real OTP verification logic
          expect(result.isSuccess, true);
          expect(result.data!.email, testEmail);
          await verifyOtpEvent;
          expect(fakeSupabaseWrapper.getMethodCallsFor('verifyOTP').length, 1);
        },
      );

      test('verifyOtp should handle invalid verification code', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnVerifyOtp = true;
        fakeSupabaseWrapper.verifyOtpErrorMessage = 'Invalid OTP';
        fakeSupabaseWrapper.authErrorCode =
            SupabaseAuthErrorCode.invalidCredentials;

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.verifyOtp(
          testEmail,
          '123456',
          OtpReceiver.email,
        );

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test('verifyOtp should fail when user verification fails', () async {
        // Arrange - Configure fake external dependency to return null
        fakeSupabaseWrapper.shouldReturnNullUser = true;

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.verifyOtp(
          testEmail,
          '123456',
          OtpReceiver.email,
        );

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test(
        'resetPassword should successfully initiate password reset',
        () async {
          // Act - Use REAL manager with REAL repository
          final result = await realAuthManager.resetPassword(testEmail);

          // Assert - Test real password reset logic
          expect(result.isSuccess, true);
          expect(
            fakeSupabaseWrapper
                .getMethodCallsFor('resetPasswordForEmail')
                .length,
            1,
          );
        },
      );

      test('resetPassword should handle reset failure', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnResetPassword = true;
        fakeSupabaseWrapper.resetPasswordErrorMessage = 'Reset failed';
        fakeSupabaseWrapper.authErrorCode =
            SupabaseAuthErrorCode.invalidCredentials;

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.resetPassword(testEmail);

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test('logout should clear auth state on success', () async {
        // Arrange - Set up expectation for auth state changes BEFORE login
        final authStateEvents = expectLater(
          authNotifier.onAuthStateChanged,
          emitsInOrder([
            predicate<AuthState>(
              (state) => state.status == AuthStatus.authenticated,
            ),
            predicate<AuthState>(
              (state) => state.status == AuthStatus.unauthenticated,
            ),
          ]),
        );

        // First login to set up state (this will emit authenticated state)
        await realAuthManager.loginWithEmail(testEmail, testPassword);

        // Act - Test logout
        final result = await realAuthManager.logout();

        // Assert
        expect(result.isSuccess, true);
        await authStateEvents;
        expect(realAuthManager.isAuthenticated(), false);
        expect(fakeSupabaseWrapper.getMethodCallsFor('signOut').length, 1);
      });

      test('logout should handle logout failure', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnSignOut = true;
        fakeSupabaseWrapper.signOutErrorMessage = 'Logout failed';

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.logout();

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });

      test('isEmailRegistered should return true for existing email', () async {
        // Arrange - Set up fake external data
        fakeSupabaseWrapper.addTableData('users', [
          {'email': testEmail},
        ]);

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.isEmailRegistered(testEmail);

        // Assert - Test real email check logic
        expect(result.isSuccess, true);
        expect(result.data, true);
      });

      test(
        'isEmailRegistered should return false for non-existing email',
        () async {
          // Act - Use REAL manager with REAL repository
          final result = await realAuthManager.isEmailRegistered(testEmail);

          // Assert - Test real email check logic
          expect(result.isSuccess, true);
          expect(result.data, false);
        },
      );
    });

    group('Input Validation with Real Components', () {
      test('loginWithEmail should reject invalid email format', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.loginWithEmail(
          'invalid-email',
          'Password123!',
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test('loginWithEmail should reject empty email', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.loginWithEmail('', 'Password123!');

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.emailRequired);
      });

      test('loginWithEmail should reject weak password', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.loginWithEmail(
          'test@example.com',
          'weak',
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.passwordTooShort);
      });

      test('loginWithEmail should reject password without uppercase', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.loginWithEmail(
          'test@example.com',
          'password123!',
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.passwordMissingUppercase);
      });

      test('registerWithEmail should reject invalid email format', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.registerWithEmail(
          'invalid-email',
          'Password123!',
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test(
        'registerWithEmail should reject password without special character',
        () async {
          // Act - Use REAL manager with REAL repository
          final result = await realAuthManager.registerWithEmail(
            'test@example.com',
            'Password123',
          );

          // Assert - Test real validation logic
          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.passwordMissingSpecialChar);
        },
      );

      test('sendOtp should reject invalid email for email receiver', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.sendOtp(
          'invalid-email',
          OtpReceiver.email,
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test('sendOtp should reject invalid phone for phone receiver', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.sendOtp(
          '123456789',
          OtpReceiver.phone,
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidPhone);
      });

      test('verifyOtp should reject invalid OTP format', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.verifyOtp(
          'test@example.com',
          '12345',
          OtpReceiver.email,
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidOtp);
      });

      test('verifyOtp should reject non-numeric OTP', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.verifyOtp(
          'test@example.com',
          '12a456',
          OtpReceiver.email,
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidOtp);
      });

      test('resetPassword should reject invalid email format', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.resetPassword('invalid-email');

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test('isEmailRegistered should reject invalid email format', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.isEmailRegistered('invalid-email');

        // Assert - Test real validation logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test('loginWithEmail should accept valid credentials', () async {
        // Arrange - Set up fake external data for successful login
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: 'test@example.com',
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.loginWithEmail(
          'test@example.com',
          'Password123!',
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, true);
      });

      test('registerWithEmail should accept valid credentials', () async {
        // Arrange - Set up fake external data for successful registration
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: 'test@example.com',
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.registerWithEmail(
          'test@example.com',
          'Password123!',
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, true);
      });

      test('sendOtp should accept valid email', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.sendOtp(
          'test@example.com',
          OtpReceiver.email,
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, true);
      });

      test('sendOtp should accept valid phone number', () async {
        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.sendOtp(
          '+1234567890',
          OtpReceiver.phone,
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, true);
      });

      test('verifyOtp should accept valid OTP format', () async {
        // Arrange - Set up fake external data for successful verification
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: 'test@example.com',
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.verifyOtp(
          'test@example.com',
          '123456',
          OtpReceiver.email,
        );

        // Assert - Test real validation logic
        expect(result.isSuccess, true);
      });
    });

    group('Testing Real Repository Business Logic', () {
      test('getUserProfile should fetch and notify on success', () async {
        // Arrange - Set up fake external data
        final testUser = createTestUser();
        fakeSupabaseWrapper.addTableData('users', [testUser.toJson()]);

        final getUserProfileEvent = expectLater(
          authNotifier.onUserProfileChanged,
          emits(predicate<User?>((user) => user!.email == testEmail)),
        );

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.getUserProfile(
          testUser.credentialId!,
        );

        // Assert - Test real repository logic
        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        await getUserProfileEvent;
        expect(authNotifier.userProfileChangedEvents.length, 1);
        expect(authNotifier.userProfileChangedEvents[0]!.email, testEmail);
      });

      test('createUserProfile should create and notify on success', () async {
        // Arrange - Set up fake external data
        final testUser = createTestUser();
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: testEmail,
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );

        final createUserProfileEvent = expectLater(
          authNotifier.onUserProfileChanged,
          emits(predicate<User?>((user) => user!.email == testEmail)),
        );

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.createUserProfile(testUser);

        // Assert - Test real repository logic
        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        await createUserProfileEvent;
        expect(authNotifier.userProfileChangedEvents.length, 1);
        expect(authNotifier.userProfileChangedEvents[0]!.email, testEmail);
      });

      test('updateUserProfile should update and notify on success', () async {
        // Arrange - Set up fake external data
        final testUser = createTestUser();
        fakeSupabaseWrapper.addTableData('users', [testUser.toJson()]);

        final updateUserProfileEvent = expectLater(
          authNotifier.onUserProfileChanged,
          emits(predicate<User?>((user) => user!.email == testEmail)),
        );

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.updateUserProfile(testUser);

        // Assert - Test real repository logic
        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        await updateUserProfileEvent;
        expect(authNotifier.userProfileChangedEvents.length, 1);
        expect(authNotifier.userProfileChangedEvents[0]!.email, testEmail);
      });

      test(
        'getCurrentCredentials should return current user credentials',
        () async {
          // Arrange - Set up fake external data
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              email: testEmail,
              id: 'test-id',
              createdAt: clock.now().toIso8601String(),
              appMetadata: {},
            ),
          );

          // Act - Use REAL manager with REAL repository
          final result = realAuthManager.getCurrentCredentials();

          // Assert - Test real repository logic
          expect(result.isSuccess, true);
          expect(result.data!.email, testEmail);
        },
      );
    });

    group('Extended User Profile Management with Real Components', () {
      test('createUserProfile should handle creation failure', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertErrorMessage = 'Failed to create profile';

        // Set up a current user so getCurrentCredentials() succeeds
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: testEmail,
            id: 'test-cred-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );

        final testUser = createTestUser();
        final result = await realAuthManager.createUserProfile(testUser);

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });

      test(
        'createUserProfile should fail if current user is not found',
        () async {
          // Arrange - Set fake external dependency to return null user
          fakeSupabaseWrapper.setCurrentUser(null);
          final testUser = createTestUser();

          // Act - Use REAL manager with REAL repository
          final result = await realAuthManager.createUserProfile(testUser);

          // Assert - Test real error handling logic
          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
        },
      );

      test('getUserProfile should handle fetch failure', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectErrorMessage = 'Failed to get profile';

        final testUser = createTestUser();
        final result = await realAuthManager.getUserProfile(
          testUser.credentialId!,
        );

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });

      test('updateUserProfile should handle update failure', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        fakeSupabaseWrapper.updateErrorMessage = 'Failed to update profile';

        final testUser = createTestUser();
        final result = await realAuthManager.updateUserProfile(testUser);

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });

      test(
        'getCurrentCredentials should return null when no user is authenticated',
        () async {
          // Arrange - Set no current user
          fakeSupabaseWrapper.setCurrentUser(null);

          // Act - Use REAL manager with REAL repository
          final result = realAuthManager.getCurrentCredentials();

          // Assert - Test real behavior (no user is not an error, just null data)
          expect(result.isSuccess, true);
          expect(result.data, null);
        },
      );
    });

    group('Testing Error Handling Integration', () {
      test('should handle network errors gracefully', () async {
        // Arrange - First login to set up state
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            email: testEmail,
            id: 'test-id',
            createdAt: clock.now().toIso8601String(),
            appMetadata: {},
          ),
        );
        await realAuthManager.loginWithEmail(testEmail, testPassword);

        // Act - Simulate network error via fake external dependency
        final errorEvent = expectLater(
          authNotifier.onAuthStateChanged,
          emits(
            predicate<AuthState>(
              (state) => state.status == AuthStatus.connectionError,
            ),
          ),
        );

        fakeSupabaseWrapper.setAuthStreamError(
          'Network error',
          exception: supabase.AuthException('Network error'),
        );

        // Assert
        await errorEvent;
      });

      test('should handle authentication failures properly', () async {
        // Arrange - Configure fake external dependency to fail
        fakeSupabaseWrapper.shouldThrowOnSignIn = true;
        fakeSupabaseWrapper.signInErrorMessage = 'Invalid credentials';
        fakeSupabaseWrapper.authErrorCode =
            SupabaseAuthErrorCode.invalidCredentials;

        // Act - Use REAL manager with REAL repository
        final result = await realAuthManager.loginWithEmail(
          testEmail,
          testPassword,
        );

        // Assert - Test real error handling logic
        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.unauthenticated,
        );
      });
    });
  });
}

/// Test module that demonstrates the Test Double pattern:
/// - Real AuthManager implementation
/// - Real AuthRepository implementation
/// - Fake external dependencies (SupabaseWrapper)
class _TestDoubleAppModule extends Module {
  @override
  List<Module> get imports => [ClockTestModule()];

  @override
  void binds(Injector i) {
    // Fake external dependency
    i.addSingleton<SupabaseWrapper>(() => FakeSupabaseWrapper(clock: i()));

    // Fake notifier (could be real if needed)
    i.addSingleton<AuthNotifierController>(() => FakeAuthNotifier());

    // REAL repository implementation with fake external dependency
    i.addSingleton<AuthRepository>(
      () => SupabaseRepositoryImpl(supabaseWrapper: i()),
    );

    // REAL manager implementation
    i.addSingleton<AuthManager>(
      () =>
          AuthManagerImpl(wrapper: i(), authRepository: i(), authNotifier: i()),
    );
  }
}
