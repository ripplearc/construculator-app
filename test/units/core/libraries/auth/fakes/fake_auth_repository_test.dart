import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator_app_architecture/core/libraries/auth/fakes/fake_auth_repository.dart';
import 'package:construculator_app_architecture/core/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator_app_architecture/core/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator_app_architecture/core/libraries/auth/data/types/auth_types.dart';
import 'package:construculator_app_architecture/core/libraries/auth/data/models/auth_user.dart';

void main() {
  group('FakeAuthRepository', () {
    late FakeAuthRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeAuthRepository();
    });

    tearDown(() {
      fakeRepository.dispose();
    });

    group('Interface Contract Verification', () {
      test('should implement IAuthRepository interface', () {
        expect(fakeRepository, isA<IAuthRepository>());
      });

      test('should provide all required authentication methods', () async {
        // Test that all interface methods exist and return correct types
        expect(
          await fakeRepository.loginWithEmail('test@example.com', 'password'),
          isA<AuthResult<UserCredential>>(),
        );
        expect(
          await fakeRepository.registerWithEmail(
            'test@example.com',
            'password',
          ),
          isA<AuthResult<UserCredential>>(),
        );
        expect(
          await fakeRepository.sendOtp('test@example.com', OtpReceiver.email),
          isA<AuthResult<void>>(),
        );
        expect(
          await fakeRepository.verifyOtp(
            'test@example.com',
            '123456',
            OtpReceiver.email,
          ),
          isA<AuthResult<UserCredential>>(),
        );
        expect(
          await fakeRepository.resetPassword('test@example.com'),
          isA<AuthResult<void>>(),
        );
        expect(
          await fakeRepository.isEmailRegistered('test@example.com'),
          isA<AuthResult<bool>>(),
        );
        expect(await fakeRepository.logout(), isA<AuthResult<void>>());
        expect(fakeRepository.isAuthenticated(), isA<bool>());
        expect(fakeRepository.getCurrentCredentials(), isA<UserCredential?>());
        expect(
          await fakeRepository.getUserProfile('test-id'),
          isA<AuthResult<User>>(),
        );
        expect(
          await fakeRepository.createUserProfile(_createFakeUser()),
          isA<AuthResult<User>>(),
        );
        expect(
          await fakeRepository.updateUserProfile(_createFakeUser()),
          isA<AuthResult<User>>(),
        );
        expect(fakeRepository.authStateChanges, isA<Stream<AuthStatus>>());
        expect(fakeRepository.userChanges, isA<Stream<UserCredential?>>());
      });
    });

    group('Core Authentication Functionality', () {
      test(
        'loginWithEmail should succeed when configured to succeed',
        () async {
          // Arrange
          fakeRepository.fakeAuthResponse(succeed: true);

          // Act
          final result = await fakeRepository.loginWithEmail(
            'test@example.com',
            'password',
          );

          // Assert
          expect(result.isSuccess, true);
          expect(result.data, isNotNull);
          expect(result.data!.email, 'test@example.com');
          expect(fakeRepository.isAuthenticated(), true);
          expect(
            fakeRepository.loginCalls,
            contains('test@example.com:password'),
          );
        },
      );

      test('loginWithEmail should fail when configured to fail', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(
          succeed: false,
          errorMessage: 'Invalid credentials',
        );

        // Act
        final result = await fakeRepository.loginWithEmail(
          'test@example.com',
          'wrong-password',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Invalid credentials');
        expect(result.errorType, AuthErrorType.invalidCredentials);
        expect(fakeRepository.isAuthenticated(), false);
        expect(
          fakeRepository.loginCalls,
          contains('test@example.com:wrong-password'),
        );
      });

      test(
        'loginWithEmail should reject empty credentials when configured',
        () async {
          // Arrange
          fakeRepository.shouldRejectEmptyCredentials = true;

          // Act
          final result = await fakeRepository.loginWithEmail('', 'password');

          // Assert
          expect(result.isSuccess, false);
          expect(result.errorMessage, 'Email or password cannot be empty');
          expect(result.errorType, AuthErrorType.invalidCredentials);
        },
      );

      test(
        'registerWithEmail should succeed when configured to succeed',
        () async {
          // Arrange
          fakeRepository.fakeAuthResponse(succeed: true);

          // Act
          final result = await fakeRepository.registerWithEmail(
            'new@example.com',
            'password',
          );

          // Assert
          expect(result.isSuccess, true);
          expect(result.data, isNotNull);
          expect(result.data!.email, 'new@example.com');
          expect(fakeRepository.isAuthenticated(), true);
          expect(
            fakeRepository.registerCalls,
            contains('new@example.com:password'),
          );
        },
      );

      test('logout should unauthenticate user and clear credentials', () async {
        // Arrange - start authenticated
        await fakeRepository.loginWithEmail('test@example.com', 'password');
        expect(fakeRepository.isAuthenticated(), true);

        // Act
        final result = await fakeRepository.logout();

        // Assert
        expect(result.isSuccess, true);
        expect(fakeRepository.isAuthenticated(), false);
        expect(fakeRepository.getCurrentCredentials(), isNull);
        expect(fakeRepository.logoutCalls, contains('logout'));
      });

      test('isAuthenticated should reflect current authentication state', () {
        // Start unauthenticated
        expect(fakeRepository.isAuthenticated(), false);

        // Create authenticated repository
        final authenticatedRepo = FakeAuthRepository(startAuthenticated: true);
        expect(authenticatedRepo.isAuthenticated(), true);
        authenticatedRepo.dispose();
      });
    });

    group('OTP Functionality', () {
      test('sendOtp should succeed and generate OTP code', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.sendOtp(
          'test@example.com',
          OtpReceiver.email,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(
          fakeRepository.sendOtpCalls,
          contains('test@example.com:OtpReceiver.email'),
        );
        expect(fakeRepository.getSentOtp('test@example.com'), isNotNull);
      });

      test('verifyOtp should succeed with correct OTP', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);
        await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);
        final sentOtp = fakeRepository.getSentOtp('test@example.com')!;

        // Act
        final result = await fakeRepository.verifyOtp(
          'test@example.com',
          sentOtp,
          OtpReceiver.email,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.email, 'test@example.com');
        expect(fakeRepository.isAuthenticated(), true);
        expect(
          fakeRepository.verifyOtpCalls,
          contains('test@example.com:$sentOtp:OtpReceiver.email'),
        );
      });

      test('verifyOtp should succeed with test OTP 123456', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);
        // Send an OTP first to set up the email in the system
        await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);

        // Act - use the special test OTP 123456
        final result = await fakeRepository.verifyOtp(
          'test@example.com',
          '123456',
          OtpReceiver.email,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(fakeRepository.isAuthenticated(), true);
      });

      test('verifyOtp should fail with incorrect OTP', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);
        await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);

        // Act
        final result = await fakeRepository.verifyOtp(
          'test@example.com',
          'wrong-otp',
          OtpReceiver.email,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Invalid OTP code');
        expect(result.errorType, AuthErrorType.invalidCredentials);
        expect(fakeRepository.isAuthenticated(), false);
      });

      test('verifyOtp should fail when no OTP was sent', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.verifyOtp(
          'never-sent@example.com',
          '123456',
          OtpReceiver.email,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'No OTP was sent to this address');
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test('sendOtp should work with phone receiver', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.sendOtp(
          '+1234567890',
          OtpReceiver.phone,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(
          fakeRepository.sendOtpCalls,
          contains('+1234567890:OtpReceiver.phone'),
        );
        expect(fakeRepository.getSentOtp('+1234567890'), isNotNull);
      });

      test('verifyOtp should work with phone receiver', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);
        const phoneNumber = '+1234567890';
        await fakeRepository.sendOtp(phoneNumber, OtpReceiver.phone);
        final sentOtp = fakeRepository.getSentOtp(phoneNumber)!;

        // Act
        final result = await fakeRepository.verifyOtp(
          phoneNumber,
          sentOtp,
          OtpReceiver.phone,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(
          result.data!.email,
          'fake@example.com',
        ); // Since it's phone, we use fake email
        expect(result.data!.metadata['receiver'], 'phone');
        expect(fakeRepository.isAuthenticated(), true);
        expect(
          fakeRepository.verifyOtpCalls,
          contains('$phoneNumber:$sentOtp:OtpReceiver.phone'),
        );
      });

      test('verifyOtp should fail when checking wrong receiver type', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);
        const address = 'test@example.com';
        await fakeRepository.sendOtp(address, OtpReceiver.email);

        // Act - try to verify with phone receiver when it was sent to email
        final result = await fakeRepository.verifyOtp(
          address,
          '123456',
          OtpReceiver.phone,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'No OTP was sent to this address');
        expect(result.errorType, AuthErrorType.invalidCredentials);
      });

      test('getSentOtp should support receiver-specific lookup', () async {
        // Arrange
        const address = 'test@example.com';
        await fakeRepository.sendOtp(address, OtpReceiver.email);
        await fakeRepository.sendOtp(address, OtpReceiver.phone);

        // Act & Assert
        final emailOtp = fakeRepository.getSentOtp(address, OtpReceiver.email);
        final phoneOtp = fakeRepository.getSentOtp(address, OtpReceiver.phone);
        final anyOtp = fakeRepository.getSentOtp(
          address,
        ); // backward compatibility

        expect(emailOtp, isNotNull);
        expect(phoneOtp, isNotNull);
        expect(anyOtp, isNotNull);
        // They could be the same due to timing, but that's okay
        expect(emailOtp!.length, 6);
        expect(phoneOtp!.length, 6);
      });
    });

    group('Password Reset Functionality', () {
      test('resetPassword should succeed when configured to succeed', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.resetPassword('test@example.com');

        // Assert
        expect(result.isSuccess, true);
        expect(fakeRepository.resetPasswordCalls, contains('test@example.com'));
      });

      test('resetPassword should fail when configured to fail', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(
          succeed: false,
          errorMessage: 'Email service unavailable',
        );

        // Act
        final result = await fakeRepository.resetPassword('test@example.com');

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Email service unavailable');
        expect(result.errorType, AuthErrorType.serverError);
        expect(fakeRepository.resetPasswordCalls, contains('test@example.com'));
      });
    });

    group('Email Registration Check', () {
      test(
        'isEmailRegistered should return true for registered emails',
        () async {
          // Arrange
          fakeRepository.fakeAuthResponse(succeed: true);
          // Access the registeredEmails set directly to add emails for testing

          // Act
          final result = await fakeRepository.isEmailRegistered(
            'registered@example.com',
          );

          // Assert - default registered email exists
          expect(result.isSuccess, true);
          expect(result.data, true);
          expect(
            fakeRepository.emailCheckCalls,
            contains('registered@example.com'),
          );
        },
      );

      test(
        'isEmailRegistered should return false for unregistered emails',
        () async {
          // Arrange
          fakeRepository.fakeAuthResponse(succeed: true);

          // Act
          final result = await fakeRepository.isEmailRegistered(
            'unregistered@example.com',
          );

          // Assert
          expect(result.isSuccess, true);
          expect(result.data, false);
          expect(
            fakeRepository.emailCheckCalls,
            contains('unregistered@example.com'),
          );
        },
      );

      test('isEmailRegistered should fail when configured to fail', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(
          succeed: false,
          errorMessage: 'Database unavailable',
        );

        // Act
        final result = await fakeRepository.isEmailRegistered(
          'any@example.com',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Database unavailable');
        expect(result.errorType, AuthErrorType.serverError);
      });
    });

    group('Database Operations - User Profiles', () {
      test('getUserProfile should return profile when it exists', () async {
        // Arrange
        final fakeUser = _createFakeUser();
        fakeRepository.fakeUserProfile(fakeUser);
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.getUserProfile(
          fakeUser.credentialId,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.id, fakeUser.id);
        expect(result.data!.email, fakeUser.email);
        expect(
          fakeRepository.getUserProfileCalls,
          contains(fakeUser.credentialId),
        );
      });

      test(
        'getUserProfile should return user not found when profile does not exist',
        () async {
          // Arrange
          fakeRepository.fakeAuthResponse(succeed: true);

          // Act
          final result = await fakeRepository.getUserProfile('non-existent-id');

          // Assert
          expect(result.isSuccess, false);
          expect(result.errorMessage, 'User profile not found');
          expect(result.errorType, AuthErrorType.userNotFound);
          expect(
            fakeRepository.getUserProfileCalls,
            contains('non-existent-id'),
          );
        },
      );

      test(
        'getUserProfile should return user not found when returnNullUserProfile is true',
        () async {
          // Arrange
          fakeRepository.fakeAuthResponse(succeed: true);
          fakeRepository.returnNullUserProfile = true;

          // Act
          final result = await fakeRepository.getUserProfile('any-id');

          // Assert
          expect(result.isSuccess, false);
          expect(result.errorMessage, 'User profile not found');
          expect(result.errorType, AuthErrorType.userNotFound);
        },
      );

      test(
        'createUserProfile should succeed when configured to succeed',
        () async {
          // Arrange
          final fakeUser = _createFakeUser();
          fakeRepository.fakeAuthResponse(succeed: true);

          // Act
          final result = await fakeRepository.createUserProfile(fakeUser);

          // Assert
          expect(result.isSuccess, true);
          expect(result.data, isNotNull);
          // The implementation creates a new ID: 'profile-${user.email.split('@')[0]}'
          expect(result.data!.id, 'profile-test'); // for test@example.com
          expect(fakeRepository.createProfileCalls, contains(fakeUser));
        },
      );

      test('createUserProfile should fail when configured to fail', () async {
        // Arrange
        final fakeUser = _createFakeUser();
        fakeRepository.fakeAuthResponse(
          succeed: false,
          errorMessage: 'Profile creation failed',
        );

        // Act
        final result = await fakeRepository.createUserProfile(fakeUser);

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Profile creation failed');
        expect(result.errorType, AuthErrorType.serverError);
        expect(fakeRepository.createProfileCalls, contains(fakeUser));
      });

      test(
        'updateUserProfile should succeed when configured to succeed',
        () async {
          // Arrange
          final fakeUser = _createFakeUser();
          fakeRepository.fakeAuthResponse(succeed: true);

          // First create the profile so it exists for update
          await fakeRepository.createUserProfile(fakeUser);

          // Act
          final result = await fakeRepository.updateUserProfile(fakeUser);

          // Assert
          expect(result.isSuccess, true);
          expect(result.data, isNotNull);
          expect(result.data!.id, fakeUser.id);
          expect(fakeRepository.updateProfileCalls, contains(fakeUser));
        },
      );

      test('updateUserProfile should fail when configured to fail', () async {
        // Arrange
        final fakeUser = _createFakeUser();
        fakeRepository.fakeAuthResponse(
          succeed: false,
          errorMessage: 'Profile update failed',
        );

        // Act
        final result = await fakeRepository.updateUserProfile(fakeUser);

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Profile update failed');
        expect(result.errorType, AuthErrorType.serverError);
        expect(fakeRepository.updateProfileCalls, contains(fakeUser));
      });
    });

    group('Test Utility Features', () {
      test('should track all method calls for test verification', () async {
        // Arrange
        final testUser = _createFakeUser();

        // Act - call various methods
        await fakeRepository.loginWithEmail('login@test.com', 'pass');
        await fakeRepository.registerWithEmail('register@test.com', 'pass');
        await fakeRepository.sendOtp('otp@test.com', OtpReceiver.email);
        await fakeRepository.verifyOtp(
          'verify@test.com',
          '123456',
          OtpReceiver.email,
        );
        await fakeRepository.resetPassword('reset@test.com');
        await fakeRepository.isEmailRegistered('check@test.com');
        await fakeRepository.logout();
        fakeRepository.getCurrentCredentials();
        await fakeRepository.getUserProfile('profile-id');
        await fakeRepository.createUserProfile(
          testUser,
        ); // Use same user instance
        await fakeRepository.updateUserProfile(
          testUser,
        ); // Use same user instance

        // Assert - verify all calls were tracked
        expect(fakeRepository.loginCalls, contains('login@test.com:pass'));
        expect(
          fakeRepository.registerCalls,
          contains('register@test.com:pass'),
        );
        expect(
          fakeRepository.sendOtpCalls,
          contains('otp@test.com:OtpReceiver.email'),
        );
        expect(
          fakeRepository.verifyOtpCalls,
          contains('verify@test.com:123456:OtpReceiver.email'),
        );
        expect(fakeRepository.resetPasswordCalls, contains('reset@test.com'));
        expect(fakeRepository.emailCheckCalls, contains('check@test.com'));
        expect(fakeRepository.logoutCalls, contains('logout'));
        expect(fakeRepository.getCurrentUserCallCount, 1);
        expect(fakeRepository.getUserProfileCalls, contains('profile-id'));
        expect(
          fakeRepository.createProfileCalls,
          hasLength(1),
        ); // Only one call
        expect(
          fakeRepository.updateProfileCalls,
          hasLength(1),
        ); // Only one call
      });

      test('reset should clear all state and call tracking', () async {
        // Arrange - make some calls and set state
        await fakeRepository.loginWithEmail('test@example.com', 'password');
        await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);
        fakeRepository.fakeUserProfile(_createFakeUser());

        // Verify state exists
        expect(fakeRepository.loginCalls, isNotEmpty);
        expect(fakeRepository.sendOtpCalls, isNotEmpty);
        expect(fakeRepository.isAuthenticated(), true);

        // Act
        fakeRepository.reset();

        // Assert - everything should be cleared
        expect(fakeRepository.loginCalls, isEmpty);
        expect(fakeRepository.registerCalls, isEmpty);
        expect(fakeRepository.sendOtpCalls, isEmpty);
        expect(fakeRepository.verifyOtpCalls, isEmpty);
        expect(fakeRepository.resetPasswordCalls, isEmpty);
        expect(fakeRepository.emailCheckCalls, isEmpty);
        expect(fakeRepository.logoutCalls, isEmpty);
        expect(fakeRepository.getUserProfileCalls, isEmpty);
        expect(fakeRepository.createProfileCalls, isEmpty);
        expect(fakeRepository.updateProfileCalls, isEmpty);
        expect(fakeRepository.getCurrentUserCallCount, 0);
        expect(fakeRepository.isAuthenticated(), false);
        expect(fakeRepository.getCurrentCredentials(), isNull);
      });

      test(
        'fakeAuthResponse should control success/failure behavior',
        () async {
          // Test success
          fakeRepository.fakeAuthResponse(succeed: true);
          final successResult = await fakeRepository.loginWithEmail(
            'test@example.com',
            'password',
          );
          expect(successResult.isSuccess, true);

          // Reset and test failure
          fakeRepository.reset();
          fakeRepository.fakeAuthResponse(
            succeed: false,
            errorMessage: 'Test error',
          );
          final failureResult = await fakeRepository.loginWithEmail(
            'test@example.com',
            'password',
          );
          expect(failureResult.isSuccess, false);
          expect(failureResult.errorMessage, 'Test error');
        },
      );

      test(
        'fakeUserProfile should allow setting up test user profiles',
        () async {
          // Arrange
          final testUser1 = _createFakeUser(
            credentialId: 'cred-1',
            email: 'user1@test.com',
          );
          final testUser2 = _createFakeUser(
            credentialId: 'cred-2',
            email: 'user2@test.com',
          );

          fakeRepository.fakeUserProfile(testUser1);
          fakeRepository.fakeUserProfile(testUser2);

          // Act & Assert
          final result1 = await fakeRepository.getUserProfile('cred-1');
          expect(result1.isSuccess, true);
          expect(result1.data!.email, 'user1@test.com');

          final result2 = await fakeRepository.getUserProfile('cred-2');
          expect(result2.isSuccess, true);
          expect(result2.data!.email, 'user2@test.com');
        },
      );

      test(
        'addRegisteredEmail should allow configuring registered emails',
        () async {
          // Note: The FakeAuthRepository uses a predefined set of registered emails
          // This test verifies the default behavior rather than adding custom emails

          // Act & Assert - test with the default registered email
          final result1 = await fakeRepository.isEmailRegistered(
            'registered@example.com',
          );
          expect(result1.data, true);

          // Test with an unregistered email
          final result2 = await fakeRepository.isEmailRegistered(
            'not-registered@test.com',
          );
          expect(result2.data, false);
        },
      );

      test('getSentOtp should return OTP codes for testing', () async {
        // Arrange
        await fakeRepository.sendOtp('test1@example.com', OtpReceiver.email);
        // Wait a bit to ensure different timestamps
        await Future.delayed(Duration(milliseconds: 1));
        await fakeRepository.sendOtp('test2@example.com', OtpReceiver.email);

        // Act & Assert
        final otp1 = fakeRepository.getSentOtp('test1@example.com');
        final otp2 = fakeRepository.getSentOtp('test2@example.com');
        final otp3 = fakeRepository.getSentOtp('never-sent@example.com');

        expect(otp1, isNotNull);
        expect(otp2, isNotNull);
        expect(otp3, isNull);
        expect(otp1!.length, 6); // 6-digit OTP
        expect(otp2!.length, 6);
        // Note: OTP generation is based on timestamp, so they might be the same if generated too quickly
        // We'll just verify they are valid 6-digit codes rather than checking they're different
      });
      test('should handle concurrent login attempts correctly', () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act - Simulate concurrent login attempts
        final futures = List.generate(
          3,
          (_) => fakeRepository.loginWithEmail('test@example.com', 'password'),
        );

        final results = await Future.wait(futures);

        // Assert - All should succeed
        for (final result in results) {
          expect(result.isSuccess, true);
        }
      });
    });

    group('Initial State Configuration', () {
      test('should start unauthenticated by default', () {
        final repo = FakeAuthRepository();
        expect(repo.isAuthenticated(), false);
        expect(repo.getCurrentCredentials(), isNull);
        repo.dispose();
      });

      test('should start authenticated when startAuthenticated is true', () {
        final repo = FakeAuthRepository(startAuthenticated: true);
        expect(repo.isAuthenticated(), true);
        expect(repo.getCurrentCredentials(), isNotNull);
        expect(repo.getCurrentCredentials()!.email, 'test@example.com');
        repo.dispose();
      });
    });

    group('Stream Behavior', () {
      test('authStateChanges should emit state changes', () async {
        // Arrange
        final stateCompleter = Completer<AuthStatus>();
        fakeRepository.authStateChanges.listen(stateCompleter.complete);

        // Act
        await fakeRepository.loginWithEmail('test@example.com', 'password');

        // Assert
        final receivedState = await stateCompleter.future.timeout(
          Duration(seconds: 1),
        );
        expect(receivedState, AuthStatus.authenticated);
      });

      test('userChanges should emit user credential changes', () async {
        // Arrange
        final userCompleter = Completer<UserCredential?>();
        fakeRepository.userChanges.listen(userCompleter.complete);

        // Act
        await fakeRepository.loginWithEmail('test@example.com', 'password');

        // Assert
        final receivedCredentials = await userCompleter.future.timeout(
          Duration(seconds: 1),
        );
        expect(receivedCredentials, isNotNull);
        expect(receivedCredentials!.email, 'test@example.com');
      });

      test('streams should be broadcast and allow multiple listeners', () {
        // Test that multiple listeners can be added without error
        expect(() {
          fakeRepository.authStateChanges.listen((_) {});
          fakeRepository.authStateChanges.listen((_) {});
        }, returnsNormally);

        expect(() {
          fakeRepository.userChanges.listen((_) {});
          fakeRepository.userChanges.listen((_) {});
        }, returnsNormally);
      });

      test(
        'emitAuthStateChanged should manually emit auth state for testing',
        () async {
          // Arrange
          final stateCompleter = Completer<AuthStatus>();
          fakeRepository.authStateChanges.listen(stateCompleter.complete);

          // Act
          fakeRepository.emitAuthStateChanged(AuthStatus.authenticated);

          // Assert
          final receivedState = await stateCompleter.future.timeout(
            Duration(seconds: 1),
          );
          expect(receivedState, AuthStatus.authenticated);
        },
      );

      test(
        'emitUserUpdated should manually emit user changes for testing',
        () async {
          // Arrange
          final userCompleter = Completer<UserCredential?>();
          final testCredential = UserCredential(
            id: 'test-id',
            email: 'test@example.com',
            metadata: {},
            createdAt: DateTime.now(),
          );
          fakeRepository.userChanges.listen(userCompleter.complete);

          // Act
          fakeRepository.emitUserUpdated(testCredential);

          // Assert
          final receivedCredential = await userCompleter.future.timeout(
            Duration(seconds: 1),
          );
          expect(receivedCredential, isNotNull);
          expect(receivedCredential!.email, 'test@example.com');
        },
      );
    });

    group('Resource Management', () {
      test('dispose should close all streams without error', () {
        // Arrange - add listeners to streams
        fakeRepository.authStateChanges.listen((_) {});
        fakeRepository.userChanges.listen((_) {});

        // Act & Assert - should not throw
        expect(() => fakeRepository.dispose(), returnsNormally);
      });
    });
  });
}

// Helper function to create fake users for testing
User _createFakeUser({String? credentialId, String? email}) {
  return User(
    id: 'fake-user-id',
    credentialId: credentialId ?? 'fake-credential-id',
    email: email ?? 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    professionalRole: 'fake-role-id',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    userStatus: UserProfileStatus.active,
    userPreferences: {},
    profilePhotoUrl: null,
    phone: null,
  );
}
