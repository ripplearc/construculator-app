import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
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

void main() {
  late FakeAuthNotifier authNotifier;
  late FakeAuthRepository authRepository;
  late FakeSupabaseWrapper supabaseWrapper;
  late AuthManager authManager;
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
    Modular.init(_TestAppModule());
    authNotifier = Modular.get<AuthNotifierController>() as FakeAuthNotifier;
    authRepository = Modular.get<AuthRepository>() as FakeAuthRepository;
    supabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    authManager = Modular.get<AuthManager>();
    clock = Modular.get<Clock>();
  });

  tearDown(() {
    Modular.destroy();
  });

  group('AuthManagerImpl', () {
    group('Initialization and State Management', () {
      test(
        'should initialize with authenticated state when user exists',
        () async {
          supabaseWrapper = FakeSupabaseWrapper(clock: clock);
          authNotifier = FakeAuthNotifier();
          supabaseWrapper.setCurrentUser(
            FakeUser(
              email: testEmail,
              id: 'test-id',
              createdAt: clock.now().toIso8601String(),
              appMetadata: {},
            ),
          );
          final initialEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) => state.status == AuthStatus.authenticated,
              ),
            ),
          );
          AuthManagerImpl(
            wrapper: supabaseWrapper,
            authRepository: authRepository,
            authNotifier: authNotifier,
          );
          await initialEvent;
          expect(authNotifier.stateChangedEvents.length, 1);
          expect(
            authNotifier.stateChangedEvents[0].status,
            AuthStatus.authenticated,
          );
          expect(authNotifier.stateChangedEvents[0].user!.email, testEmail);
        },
      );

      test(
        'loginWithEmail should emit authenticated state on success',
        () async {
          final loginEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) =>
                    state.status == AuthStatus.authenticated &&
                    state.user!.email == testEmail,
              ),
            ),
          );

          final result = await authManager.loginWithEmail(
            testEmail,
            testPassword,
          );
          expect(result.isSuccess, true);
          await loginEvent;
        },
      );

      test('loginWithEmail should fail when user is not found', () async {
        supabaseWrapper.shouldReturnNullUser = true;

        final result = await authManager.loginWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test('logout should emit unauthenticated state', () async {
        await authManager.loginWithEmail(testEmail, testPassword);

        final logoutEvent = expectLater(
          authNotifier.onAuthStateChanged,
          emits(
            predicate<AuthState>(
              (state) => state.status == AuthStatus.unauthenticated,
            ),
          ),
        );

        final result = await authManager.logout();
        expect(result.isSuccess, true);
        await logoutEvent;
      });

      test('session expiry should emit unauthenticated state', () async {
        await authManager.loginWithEmail(testEmail, testPassword);

        final expiryEvent = expectLater(
          authNotifier.onAuthStateChanged,
          emits(
            predicate<AuthState>(
              (state) => state.status == AuthStatus.unauthenticated,
            ),
          ),
        );

        supabaseWrapper.setAuthStreamError(
          'Auth session missing',
          exception: supabase.AuthSessionMissingException(),
        );
        await expiryEvent;
      });

      test('network error should emit connection error state', () async {
        await authManager.loginWithEmail(testEmail, testPassword);

        final errorEvent = expectLater(
          authNotifier.onAuthStateChanged,
          emits(
            predicate<AuthState>(
              (state) => state.status == AuthStatus.connectionError,
            ),
          ),
        );

        supabaseWrapper.setAuthStreamError(
          'Network error',
          exception: supabase.AuthException('Network error'),
        );
        await errorEvent;
      });

      test('should transition through expected auth states', () async {
        final eventListener = expectLater(
          authNotifier.onAuthStateChanged,
          emitsInOrder([
            predicate<AuthState>(
              (state) => state.status == AuthStatus.authenticated,
            ),
            predicate<AuthState>(
              (state) => state.status == AuthStatus.unauthenticated,
            ),
            predicate<AuthState>(
              (state) => state.status == AuthStatus.connectionError,
            ),
            predicate<AuthState>(
              (state) => state.status == AuthStatus.unauthenticated,
            ),
          ]),
        );
        await authManager.loginWithEmail(testEmail, testPassword);
        supabaseWrapper.setAuthStreamError(
          'Auth session missing',
          exception: supabase.AuthSessionMissingException(),
        );
        supabaseWrapper.setAuthStreamError(
          'Network error',
          exception: supabase.AuthException('Network error'),
        );
        await authManager.logout();

        await eventListener;

        expect(authNotifier.stateChangedEvents.map((s) => s.status), [
          AuthStatus.unauthenticated,
          AuthStatus.authenticated,
          AuthStatus.unauthenticated,
          AuthStatus.connectionError,
          AuthStatus.unauthenticated,
        ]);
      });
    });

    group('Authentication Operations', () {
      test(
        'loginWithEmail should authenticate and update state on success',
        () async {
          final loginEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) => state.status == AuthStatus.authenticated,
              ),
            ),
          );
          final result = await authManager.loginWithEmail(
            testEmail,
            testPassword,
          );
          expect(result.isSuccess, true);
          expect(result.data!.email, testEmail);
          await loginEvent;
          expect(authNotifier.stateChangedEvents.length, 2);
          expect(
            authNotifier.stateChangedEvents[0].status,
            AuthStatus.unauthenticated,
          );
          expect(
            authNotifier.stateChangedEvents[1].status,
            AuthStatus.authenticated,
          );
          expect(
            supabaseWrapper.getMethodCallsFor('signInWithPassword').length,
            1,
          );
        },
      );

      test('loginWithEmail should handle authentication failure', () async {
        supabaseWrapper.shouldThrowOnSignIn = true;
        supabaseWrapper.signInErrorMessage = 'Invalid credentials';
        supabaseWrapper.authErrorCode =
            SupabaseAuthErrorCode.invalidCredentials;

        final result = await authManager.loginWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
        expect(
          authNotifier.stateChangedEvents.last.status,
          AuthStatus.unauthenticated,
        );
      });

      test(
        'registerWithEmail should create account and authenticate on success',
        () async {
          final registerEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) => state.status == AuthStatus.authenticated,
              ),
            ),
          );
          final result = await authManager.registerWithEmail(
            testEmail,
            testPassword,
          );

          expect(result.isSuccess, true);
          expect(result.data!.email, testEmail);
          await registerEvent;
          expect(authNotifier.stateChangedEvents.length, 2);
          expect(
            authNotifier.stateChangedEvents[0].status,
            AuthStatus.unauthenticated,
          );
          expect(
            authNotifier.stateChangedEvents[1].status,
            AuthStatus.authenticated,
          );
          expect(supabaseWrapper.getMethodCallsFor('signUp').length, 1);
        },
      );

      test('registerWithEmail should handle registration failure', () async {
        supabaseWrapper.shouldThrowOnSignUp = true;
        supabaseWrapper.signUpErrorMessage = 'Registration failed';
        supabaseWrapper.authErrorCode =
            SupabaseAuthErrorCode.registrationFailure;

        final result = await authManager.registerWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.registrationFailure);
      });

      test('registerWithEmail should fail when user creation fails', () async {
        supabaseWrapper.shouldReturnNullUser = true;

        final result = await authManager.registerWithEmail(
          testEmail,
          testPassword,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.registrationFailure);
      });

      test('sendOtp should successfully send verification code', () async {
        final result = await authManager.sendOtp(testEmail, OtpReceiver.email);

        expect(result.isSuccess, true);
        expect(supabaseWrapper.getMethodCallsFor('signInWithOtp').length, 1);
      });

      test('sendOtp should handle sending failure', () async {
        supabaseWrapper.shouldThrowOnOtp = true;
        supabaseWrapper.otpErrorMessage = 'Failed to send OTP';
        supabaseWrapper.authErrorCode = SupabaseAuthErrorCode.timeout;

        final result = await authManager.sendOtp(testEmail, OtpReceiver.email);

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.timeout);
      });

      test(
        'verifyOtp should authenticate user on successful verification',
        () async {
          final verifyOtpEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) => state.status == AuthStatus.authenticated,
              ),
            ),
          );
          final result = await authManager.verifyOtp(
            testEmail,
            '123456',
            OtpReceiver.email,
          );

          expect(result.isSuccess, true);
          expect(result.data!.email, testEmail);
          await verifyOtpEvent;
          expect(authNotifier.stateChangedEvents.length, 2);
          expect(
            authNotifier.stateChangedEvents[0].status,
            AuthStatus.unauthenticated,
          );
          expect(
            authNotifier.stateChangedEvents[1].status,
            AuthStatus.authenticated,
          );
          expect(supabaseWrapper.getMethodCallsFor('verifyOTP').length, 1);
        },
      );

      test('verifyOtp should handle invalid verification code', () async {
        supabaseWrapper.shouldThrowOnVerifyOtp = true;
        supabaseWrapper.verifyOtpErrorMessage = 'Invalid OTP';
        supabaseWrapper.authErrorCode =
            SupabaseAuthErrorCode.invalidCredentials;

        final result = await authManager.verifyOtp(
          testEmail,
          '123456',
          OtpReceiver.email,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test('verifyOtp should fail when user verification fails', () async {
        supabaseWrapper.shouldReturnNullUser = true;

        final result = await authManager.verifyOtp(
          testEmail,
          '123456',
          OtpReceiver.email,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test(
        'resetPassword should successfully initiate password reset',
        () async {
          final result = await authManager.resetPassword(testEmail);

          expect(result.isSuccess, true);
          expect(
            supabaseWrapper.getMethodCallsFor('resetPasswordForEmail').length,
            1,
          );
        },
      );

      test('resetPassword should handle reset failure', () async {
        supabaseWrapper.shouldThrowOnResetPassword = true;
        supabaseWrapper.resetPasswordErrorMessage = 'Reset failed';
        supabaseWrapper.authErrorCode =
            SupabaseAuthErrorCode.invalidCredentials;

        final result = await authManager.resetPassword(testEmail);

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test('logout should clear auth state on success', () async {
        final logoutEvent = expectLater(
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
        await authManager.loginWithEmail(testEmail, testPassword);

        final result = await authManager.logout();

        expect(result.isSuccess, true);
        await logoutEvent;
        expect(authNotifier.stateChangedEvents.length, 3);
        expect(
          authNotifier.stateChangedEvents[0].status,
          AuthStatus.unauthenticated,
        );
        expect(
          authNotifier.stateChangedEvents[1].status,
          AuthStatus.authenticated,
        );
        expect(
          authNotifier.stateChangedEvents[2].status,
          AuthStatus.unauthenticated,
        );
        expect(authManager.isAuthenticated(), false);
        expect(supabaseWrapper.getMethodCallsFor('signOut').length, 1);
      });

      test('logout should handle logout failure', () async {
        supabaseWrapper.shouldThrowOnSignOut = true;
        supabaseWrapper.signOutErrorMessage = 'Logout failed';

        final result = await authManager.logout();

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });

      test('isEmailRegistered should return true for existing email', () async {
        supabaseWrapper.addTableData('users', [
          {'email': testEmail},
        ]);
        final result = await authManager.isEmailRegistered(testEmail);

        expect(result.isSuccess, true);
        expect(result.data, true);
      });

      test(
        'isEmailRegistered should return false for non-existing email',
        () async {
          final result = await authManager.isEmailRegistered(testEmail);

          expect(result.isSuccess, true);
          expect(result.data, false);
        },
      );
    });

    group('Input Validation', () {
      test('loginWithEmail should reject invalid email format', () async {
        final result = await authManager.loginWithEmail(
          'invalid-email',
          'Password123!',
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test('loginWithEmail should reject empty email', () async {
        final result = await authManager.loginWithEmail('', 'Password123!');

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.emailRequired);
      });

      test('loginWithEmail should reject weak password', () async {
        final result = await authManager.loginWithEmail(
          'test@example.com',
          'weak',
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.passwordTooShort);
      });

      test('loginWithEmail should reject password without uppercase', () async {
        final result = await authManager.loginWithEmail(
          'test@example.com',
          'password123!',
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.passwordMissingUppercase);
      });

      test('registerWithEmail should reject invalid email format', () async {
        final result = await authManager.registerWithEmail(
          'invalid-email',
          'Password123!',
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test(
        'registerWithEmail should reject password without special character',
        () async {
          final result = await authManager.registerWithEmail(
            'test@example.com',
            'Password123',
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.passwordMissingSpecialChar);
        },
      );

      test('sendOtp should reject invalid email for email receiver', () async {
        final result = await authManager.sendOtp(
          'invalid-email',
          OtpReceiver.email,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test('sendOtp should reject invalid phone for phone receiver', () async {
        final result = await authManager.sendOtp(
          '123456789',
          OtpReceiver.phone,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidPhone);
      });

      test('verifyOtp should reject invalid OTP format', () async {
        final result = await authManager.verifyOtp(
          'test@example.com',
          '12345',
          OtpReceiver.email,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidOtp);
      });

      test('verifyOtp should reject non-numeric OTP', () async {
        final result = await authManager.verifyOtp(
          'test@example.com',
          '12a456',
          OtpReceiver.email,
        );

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidOtp);
      });

      test('resetPassword should reject invalid email format', () async {
        final result = await authManager.resetPassword('invalid-email');

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test('isEmailRegistered should reject invalid email format', () async {
        final result = await authManager.isEmailRegistered('invalid-email');

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.invalidEmail);
      });

      test('loginWithEmail should accept valid credentials', () async {
        final result = await authManager.loginWithEmail(
          'test@example.com',
          'Password123!',
        );

        expect(result.isSuccess, true);
      });

      test('registerWithEmail should accept valid credentials', () async {
        final result = await authManager.registerWithEmail(
          'test@example.com',
          'Password123!',
        );

        expect(result.isSuccess, true);
      });

      test('sendOtp should accept valid email', () async {
        final result = await authManager.sendOtp(
          'test@example.com',
          OtpReceiver.email,
        );

        expect(result.isSuccess, true);
      });

      test('sendOtp should accept valid phone number', () async {
        final result = await authManager.sendOtp(
          '+1234567890',
          OtpReceiver.phone,
        );

        expect(result.isSuccess, true);
      });

      test('verifyOtp should accept valid OTP format', () async {
        final result = await authManager.verifyOtp(
          'test@example.com',
          '123456',
          OtpReceiver.email,
        );

        expect(result.isSuccess, true);
      });
    });

    group('User Profile Management', () {
      group('updateUserEmail', () {
        test('should update email and password successfully', () async {
          final credential = UserCredential(
            id: 'test-id',
            email: 'old@example.com',
            metadata: {},
            createdAt: clock.now(),
          );
          authRepository.setCurrentCredentials(credential);
          authRepository.setAuthResponse(succeed: true);

          final result = await authManager.updateUserEmail('new@example.com');

          expect(result.isSuccess, true);
          expect(result.data!.email, 'new@example.com');
          expect(authRepository.createProfileCalls.length, 0);
          expect(authRepository.updateProfileCalls.length, 0);
        });

        test('should update only email when password is null', () async {
          final credential = UserCredential(
            id: 'test-id',
            email: 'old@example.com',
            metadata: {},
            createdAt: clock.now(),
          );
          authRepository.setCurrentCredentials(credential);
          authRepository.setAuthResponse(succeed: true);

          final result = await authManager.updateUserPassword('newpass123');

          expect(result.isSuccess, true);
          expect(authRepository.createProfileCalls.length, 0);
          expect(authRepository.updateProfileCalls.length, 0);
        });

        test('should update only password when email is null', () async {
          final credential = UserCredential(
            id: 'test-id',
            email: 'old@example.com',
            metadata: {},
            createdAt: clock.now(),
          );
          authRepository.setCurrentCredentials(credential);
          authRepository.setAuthResponse(succeed: true);

          final result = await authManager.updateUserPassword('newpass123');

          expect(result.isSuccess, true);
          expect(result.data!.metadata['password'], 'newpass123');
          expect(authRepository.createProfileCalls.length, 0);
          expect(authRepository.updateProfileCalls.length, 0);
        });

        test('should handle update failure', () async {
          authRepository.setAuthResponse(succeed: false);
          authRepository.exceptionMessage = 'Update failed';

          final result = await authManager.updateUserEmail('new@example.com');

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.serverError);
        });

        test('should handle errors when credentials does not exist', () async {
          authRepository.setAuthResponse(succeed: false);
          final result = await authManager.updateUserPassword(
            'new@example.com',
          );

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.serverError);
        });

        test('should emit auth state change on success', () async {
          final credential = UserCredential(
            id: 'test-id',
            email: 'old@example.com',
            metadata: {},
            createdAt: clock.now(),
          );
          authRepository.setCurrentCredentials(credential);
          authRepository.setAuthResponse(succeed: true);

          final stateChangeEvent = expectLater(
            authNotifier.onAuthStateChanged,
            emits(
              predicate<AuthState>(
                (state) =>
                    state.status == AuthStatus.authenticated &&
                    state.user!.email == 'new@example.com',
              ),
            ),
          );

          final result = await authManager.updateUserEmail('new@example.com');

          expect(result.isSuccess, true);
          await stateChangeEvent;
          expect(authNotifier.stateChangedEvents.length, 2);
          expect(
            authNotifier.stateChangedEvents[1].user!.email,
            'new@example.com',
          );
        });
      });
      test('createUserProfile should create and notify on success', () async {
        final createUserProfileEvent = expectLater(
          authNotifier.onUserProfileChanged,
          emits(predicate<User?>((user) => user!.email == testEmail)),
        );
        final testUser = createTestUser();
        authRepository.setAuthResponse(succeed: true);
        authRepository.setCurrentCredentials(
          UserCredential(
            id: 'test-id',
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          ),
        );

        final result = await authManager.createUserProfile(testUser);

        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        expect(authRepository.createProfileCalls.length, 1);
        await createUserProfileEvent;
        expect(authNotifier.userProfileChangedEvents.length, 1);
        expect(authNotifier.userProfileChangedEvents[0]!.email, testEmail);
      });

      test('createUserProfile should handle creation failure', () async {
        authRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Failed to create profile',
        );
        final testUser = createTestUser();
        final result = await authManager.createUserProfile(testUser);

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });
      test(
        'createUserProfile should fail if current user is not found',
        () async {
          supabaseWrapper.setCurrentUser(null);
          final testUser = createTestUser();
          final result = await authManager.createUserProfile(testUser);

          expect(result.isSuccess, false);
          expect(result.errorType, AuthErrorType.invalidCredentials);
        },
      );
      test('getUserProfile should fetch and notify on success', () async {
        final getUserProfileEvent = expectLater(
          authNotifier.onUserProfileChanged,
          emits(predicate<User?>((user) => user!.email == testEmail)),
        );
        final testUser = createTestUser();
        authRepository.setUserProfile(testUser);

        final result = await authManager.getUserProfile(testUser.credentialId!);

        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        expect(authRepository.getUserProfileCalls.length, 1);
        await getUserProfileEvent;
        expect(authNotifier.userProfileChangedEvents.length, 1);
        expect(authNotifier.userProfileChangedEvents[0]!.email, testEmail);
      });

      test('getUserProfile should handle fetch failure', () async {
        authRepository.shouldThrowOnGetUserProfile = true;
        final testUser = createTestUser();
        final result = await authManager.getUserProfile(testUser.credentialId!);

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });

      test('updateUserProfile should update and notify on success', () async {
        final updateUserProfileEvent = expectLater(
          authNotifier.onUserProfileChanged,
          emits(predicate<User?>((user) => user!.email == testEmail)),
        );
        final testUser = createTestUser();
        authRepository.setUserProfile(testUser);

        final result = await authManager.updateUserProfile(testUser);

        expect(result.isSuccess, true);
        expect(result.data!.email, testEmail);
        expect(authRepository.updateProfileCalls.length, 1);
        await updateUserProfileEvent;
        expect(authNotifier.userProfileChangedEvents.length, 1);
        expect(authNotifier.userProfileChangedEvents[0]!.email, testEmail);
      });

      test('updateUserProfile should handle update failure', () async {
        authRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Failed to update profile',
        );
        final testUser = createTestUser();
        final result = await authManager.updateUserProfile(testUser);

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });

      test(
        'getCurrentCredentials should return current user credentials',
        () async {
          final credential = UserCredential(
            id: 'test-id',
            email: testEmail,
            metadata: {},
            createdAt: clock.now(),
          );
          authRepository.setCurrentCredentials(credential);

          final result = authManager.getCurrentCredentials();

          expect(result.isSuccess, true);
          expect(result.data!.email, testEmail);
          expect(authRepository.getCurrentUserCallCount, 1);
        },
      );

      test('getCurrentCredentials should handle retrieval failure', () async {
        authRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Failed to get credentials',
        );

        final result = authManager.getCurrentCredentials();

        expect(result.isSuccess, false);
        expect(result.errorType, AuthErrorType.serverError);
      });
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [ClockTestModule()];
  @override
  void binds(Injector i) {
    i.addSingleton<AuthNotifierController>(() => FakeAuthNotifier());
    i.addSingleton<AuthRepository>(() => FakeAuthRepository(clock: i()));
    i.addSingleton<SupabaseWrapper>(() => FakeSupabaseWrapper(clock: i()));
    i.add<AuthManager>(
      () =>
          AuthManagerImpl(wrapper: i(), authRepository: i(), authNotifier: i()),
    );
  }
}
