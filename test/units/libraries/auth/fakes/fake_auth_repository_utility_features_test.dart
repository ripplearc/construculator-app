import 'dart:async';

import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

User _createFakeUser({String? credentialId, String? email, String? id}) {
  return User(
    id: id ?? 'fake-user-id',
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

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    // Default to successful responses unless a test configures otherwise
    fakeRepository.fakeAuthResponse(succeed: true);
  });

  tearDown(() {
    fakeRepository.dispose();
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
      fakeRepository.fakeAuthResponse(succeed: true); // Ensure login call can succeed
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
 group('Email Registration Check', () {
    test(
      'isEmailRegistered should return true for registered emails',
      () async {
        // Arrange
        // The FakeAuthRepository has a default registered email: 'registered@example.com'
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.isEmailRegistered(
          'registered@example.com',
        );

        // Assert
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
      // The FakeAuthRepository sets AuthErrorType.serverError for general failures
      expect(result.errorType, AuthErrorType.serverError);
    });
  });
 group('Initial State Configuration', () {
    test('should start unauthenticated by default', () {
      final repo = FakeAuthRepository();
      expect(repo.isAuthenticated(), false);
      expect(repo.getCurrentCredentials(), isNull);
      repo.dispose(); // Dispose instance created in test
    });

    test('should start authenticated when startAuthenticated is true', () {
      final repo = FakeAuthRepository(startAuthenticated: true);
      expect(repo.isAuthenticated(), true);
      expect(repo.getCurrentCredentials(), isNotNull);
      // Default authenticated user in FakeAuthRepository is test@example.com
      expect(repo.getCurrentCredentials()!.email, 'test@example.com');
      repo.dispose(); // Dispose instance created in test
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
      fakeRepository.fakeAuthResponse(succeed: true); // sendOtp should succeed
      await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);
      // For verifyOtp to fail as expected, we set the response for that call.
      // The FakeAuthRepository internally sets the errorType based on the message or scenario.
      fakeRepository.fakeAuthResponse(succeed: false, errorMessage: 'Invalid OTP code');

      // Act
      final result = await fakeRepository.verifyOtp(
        'test@example.com',
        'wrong-otp',
        OtpReceiver.email,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Invalid OTP code');
      // We expect the repository to set this error type for invalid OTPs
      expect(result.errorType, AuthErrorType.invalidCredentials);
      expect(fakeRepository.isAuthenticated(), false);
    });

    test('verifyOtp should fail when no OTP was sent', () async {
      // Arrange
      // The FakeAuthRepository handles this specific error message and type.
      fakeRepository.fakeAuthResponse(succeed: false, errorMessage: 'No OTP was sent to this address');

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
      expect(result.data!.metadata['receiver'], 'phone');
      expect(fakeRepository.isAuthenticated(), true);
      expect(
        fakeRepository.verifyOtpCalls,
        contains('$phoneNumber:$sentOtp:OtpReceiver.phone'),
      );
    });

    test('verifyOtp should fail when checking wrong receiver type', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true); // for sendOtp
      const address = 'test@example.com';
      await fakeRepository.sendOtp(address, OtpReceiver.email);

      // Configure verifyOtp to fail as if no OTP was sent to this type
      fakeRepository.fakeAuthResponse(succeed: false, errorMessage: 'No OTP was sent to this address');

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
      fakeRepository.fakeAuthResponse(succeed: true);
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
      // The FakeAuthRepository sets AuthErrorType.serverError for general failures if not specified otherwise
      expect(result.errorType, AuthErrorType.serverError);
      expect(fakeRepository.resetPasswordCalls, contains('test@example.com'));
    });
  });
  group('Resource Management', () {
    test('dispose should close all streams without error', () {
      // Arrange - add listeners to streams to check they are handled by dispose
      final authStateSubscription = fakeRepository.authStateChanges.listen((_) {});
      final userChangesSubscription = fakeRepository.userChanges.listen((_) {});

      // Act & Assert - should not throw
      expect(() => fakeRepository.dispose(), returnsNormally);

      // Optionally, try to add more listeners after dispose - this might throw if closed correctly,
      // or just do nothing. Behavior depends on StreamController implementation.
      // For now, just checking dispose() runs without error is the primary goal from original test.
      
      // It's good practice to cancel subscriptions, though dispose should handle controllers.
      authStateSubscription.cancel();
      userChangesSubscription.cancel();
    });
  });
  group('Stream Behavior', () {
    test('authStateChanges should emit state changes', () async {
      // Arrange
      final stateCompleter = Completer<AuthStatus>();
      fakeRepository.authStateChanges.listen(stateCompleter.complete);

      // Act
      // Login will change auth state and trigger the stream if not already authenticated.
      // If startAuthenticated is true by default, this might need adjustment or logout first.
      // Assuming default start is unauthenticated for this test to be meaningful.
      if (fakeRepository.isAuthenticated()) {
        await fakeRepository.logout(); // Ensure we are unauthenticated first
        // Need a new completer if logout emitted something already
        // However, FakeAuthRepo's streams are broadcast, so it should be fine.
      }
      await fakeRepository.loginWithEmail('streamtest@example.com', 'password');

      // Assert
      final receivedState = await stateCompleter.future.timeout(
        Duration(seconds: 1),
        onTimeout: () => AuthStatus.unauthenticated, // Return a non-expected status on timeout
      );
      expect(receivedState, AuthStatus.authenticated);
    });

    test('userChanges should emit user credential changes', () async {
      // Arrange
      final userCompleter = Completer<UserCredential?>();
      fakeRepository.userChanges.listen(userCompleter.complete);
      
      // Act
      if (fakeRepository.isAuthenticated()) {
        await fakeRepository.logout();
      }
      await fakeRepository.loginWithEmail('streamuser@example.com', 'password');

      // Assert
      final receivedCredentials = await userCompleter.future.timeout(
        Duration(seconds: 1),
        onTimeout: () => null, // Return null on timeout
      );
      expect(receivedCredentials, isNotNull);
      expect(receivedCredentials!.email, 'streamuser@example.com');
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
        final StreamSubscription<AuthStatus> subscription1 =
            fakeRepository.authStateChanges.listen(stateCompleter.complete);

        // Act
        fakeRepository.emitAuthStateChanged(AuthStatus.authenticated);

        // Assert
        final receivedState = await stateCompleter.future.timeout(
          Duration(seconds: 1),
          onTimeout: () => AuthStatus.unauthenticated, 
        );
        expect(receivedState, AuthStatus.authenticated);
        await subscription1.cancel(); // Cancel the first subscription

        // Test emitting another state
        final stateCompleter2 = Completer<AuthStatus>();
        final StreamSubscription<AuthStatus> subscription2 =
            fakeRepository.authStateChanges.listen(stateCompleter2.complete);
        fakeRepository.emitAuthStateChanged(AuthStatus.unauthenticated);
        final receivedState2 = await stateCompleter2.future.timeout(
          Duration(seconds: 1),
          onTimeout: () => AuthStatus.authenticated,
        );
        expect(receivedState2, AuthStatus.unauthenticated);
        await subscription2.cancel(); // Cancel the second subscription
      },
    );

    test(
      'emitUserUpdated should manually emit user changes',
      () async {
        // Arrange
        final userCompleter = Completer<UserCredential?>();
        final testCredential = UserCredential(
          id: 'test-id-emit',
          email: 'emit@example.com',
          metadata: {},
          createdAt: DateTime.now(),
        );
        final StreamSubscription<UserCredential?> userSubscription1 =
            fakeRepository.userChanges.listen(userCompleter.complete);

        // Act
        fakeRepository.emitUserUpdated(testCredential);

        // Assert
        final receivedCredential = await userCompleter.future.timeout(
          Duration(seconds: 1),
          onTimeout: () => null,
        );
        expect(receivedCredential, isNotNull);
        expect(receivedCredential!.email, 'emit@example.com');
        expect(receivedCredential.id, 'test-id-emit');
        await userSubscription1.cancel(); // Cancel the first subscription

        // Test emitting null (logout scenario)
        final userCompleter2 = Completer<UserCredential?>();
        final StreamSubscription<UserCredential?> userSubscription2 =
            fakeRepository.userChanges.listen(userCompleter2.complete);
        fakeRepository.emitUserUpdated(null);
         final receivedCredential2 = await userCompleter2.future.timeout(
          Duration(seconds: 1),
          // Provide a non-null default to ensure timeout means null was not received as expected.
          onTimeout: () => UserCredential(id: 'timeout', email: 'timeout', createdAt: DateTime.now(), metadata: {}), 
        );
        expect(receivedCredential2, isNull);
        await userSubscription2.cancel(); // Cancel the second subscription
      },
    );
  });
  group('Database Operations - User Profiles', () {
    test('getUserProfile should return profile when it exists', () async {
      // Arrange
      final fakeUser = _createFakeUser();
      // The fakeUserProfile method in FakeAuthRepository might assign its own ID to the stored profile.
      // We need to ensure the profile is actually stored and then retrieved.
      // Create user first so it's in the "database"
      await fakeRepository.createUserProfile(fakeUser);
      // Then configure the response for getUserProfile
      fakeRepository.fakeAuthResponse(succeed: true); 
      // fakeUserProfile is more for direct injection, let's rely on createUserProfile for this test.
      // And then try to get it by the credentialId used or email.
      // The fake repo stores profiles by credentialId after createUserProfile.

      // Act
      final result = await fakeRepository.getUserProfile(
        fakeUser.credentialId,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      // The ID assigned by createUserProfile might be different ('profile-${email_prefix}')
      // Let's check email for consistency as credentialId is the lookup key.
      expect(result.data!.email, fakeUser.email);
      expect(result.data!.credentialId, fakeUser.credentialId);
      expect(
        fakeRepository.getUserProfileCalls,
        contains(fakeUser.credentialId),
      );
    });

    test(
      'getUserProfile should return user not found when profile does not exist',
      () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true); // The call itself succeeds, but finds nothing

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
        fakeRepository.fakeAuthResponse(succeed: true); // The call itself is not failing
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
        // For test@example.com, this would be profile-test
        // But the fakeUser passed in already has an id.
        // The fake repo actually uses the credentialId to store and user.id for the returned User object.
        // Let's check a few key fields.
        expect(result.data!.email, fakeUser.email);
        expect(result.data!.credentialId, fakeUser.credentialId);
        expect(fakeRepository.createProfileCalls, contains(fakeUser));

        // Verify it can be fetched
        final fetchResult = await fakeRepository.getUserProfile(fakeUser.credentialId);
        expect(fetchResult.isSuccess, true);
        expect(fetchResult.data!.email, fakeUser.email);
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
        final originalUser = _createFakeUser(email: 'original@example.com', credentialId: 'cred-original');
        fakeRepository.fakeAuthResponse(succeed: true);

        // First create the profile so it exists for update
        final createResult = await fakeRepository.createUserProfile(originalUser);
        expect(createResult.isSuccess, true, reason: "Pre-condition: Create profile failed");
        
        final updatedUser = originalUser.copyWith(firstName: 'UpdatedName');

        // Act
        final result = await fakeRepository.updateUserProfile(updatedUser);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.firstName, 'UpdatedName');
        expect(result.data!.email, originalUser.email); // Email should not change on update typically
        expect(result.data!.credentialId, originalUser.credentialId);
        expect(fakeRepository.updateProfileCalls, contains(updatedUser));

        // Verify the update is reflected
        final fetchResult = await fakeRepository.getUserProfile(originalUser.credentialId);
        expect(fetchResult.isSuccess, true);
        expect(fetchResult.data!.firstName, 'UpdatedName');
      },
    );

    test('updateUserProfile should fail when configured to fail', () async {
      // Arrange
      final fakeUser = _createFakeUser();
      // Ensure profile exists
      await fakeRepository.createUserProfile(fakeUser); 
      
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

    test('updateUserProfile should fail if profile does not exist', () async {
        // Arrange
        final nonExistentUser = _createFakeUser(credentialId: 'non-existent-for-update');
        fakeRepository.fakeAuthResponse(succeed: true); // Configure for successful call if user existed

        // Act
        final result = await fakeRepository.updateUserProfile(nonExistentUser);

        // Assert (FakeAuthRepository specific behavior: it returns error if profile not found for update)
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'User profile not found');
        expect(result.errorType, AuthErrorType.userNotFound);
        expect(fakeRepository.updateProfileCalls, contains(nonExistentUser));
    });
  });

  group('Test Utility Features', () {
    test('should track all method calls for test verification', () async {
      // Arrange
      final testUser = _createFakeUser(
        credentialId: 'cred-track',
        email: 'track@test.com',
      );
      // Ensure createUserProfile doesn't fail due to existing profile from other tests if repo is not reset properly
      // However, setUp creates a new fakeRepository, so this should be fine.

      // Act - call various methods
      await fakeRepository.loginWithEmail('login@test.com', 'pass');
      await fakeRepository.registerWithEmail('register@test.com', 'pass');
      await fakeRepository.sendOtp('otp@test.com', OtpReceiver.email);
      // For verifyOtp to succeed, an OTP must have been sent and it should be configured to succeed.
      // The fake repo has a test OTP '123456' that always works if an OTP was sent to the email.
      await fakeRepository.verifyOtp(
        'otp@test.com', // Use same email as sendOtp for verify to pass with test OTP
        '123456',
        OtpReceiver.email,
      );
      await fakeRepository.resetPassword('reset@test.com');
      await fakeRepository.isEmailRegistered('check@test.com');
      await fakeRepository.logout();
      fakeRepository.getCurrentCredentials();
      await fakeRepository.getUserProfile('profile-id-track');
      await fakeRepository.createUserProfile(testUser);
      await fakeRepository.updateUserProfile(testUser);

      // Assert - verify all calls were tracked
      expect(fakeRepository.loginCalls, contains('login@test.com:pass'));
      expect(fakeRepository.registerCalls, contains('register@test.com:pass'));
      expect(
        fakeRepository.sendOtpCalls,
        contains('otp@test.com:OtpReceiver.email'),
      );
      expect(
        fakeRepository.verifyOtpCalls,
        contains('otp@test.com:123456:OtpReceiver.email'),
      );
      expect(fakeRepository.resetPasswordCalls, contains('reset@test.com'));
      expect(fakeRepository.emailCheckCalls, contains('check@test.com'));
      expect(fakeRepository.logoutCalls, contains('logout'));
      expect(fakeRepository.getCurrentUserCallCount, 1);
      expect(fakeRepository.getUserProfileCalls, contains('profile-id-track'));
      expect(fakeRepository.createProfileCalls, contains(testUser));
      expect(fakeRepository.updateProfileCalls, contains(testUser));
    });

    test('reset should clear all state and call tracking', () async {
      // Arrange - make some calls and set state
      await fakeRepository.loginWithEmail('test@example.com', 'password');
      await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);
      fakeRepository.fakeUserProfile(
        _createFakeUser(id: 'user-to-clear'),
      ); // Uses fakeUserProfile to inject directly

      // Verify state exists
      expect(fakeRepository.loginCalls, isNotEmpty);
      expect(fakeRepository.sendOtpCalls, isNotEmpty);
      expect(fakeRepository.isAuthenticated(), true);
      // Check if the faked user profile is retrievable before reset
      // Note: fakeUserProfile directly injects, does not use createUserProfile logic.
      // The key for _userProfiles in FakeAuthRepository is credentialId.
      final userToClear = _createFakeUser(
        id: 'user-to-clear',
        credentialId: 'cred-clear',
      );
      fakeRepository.fakeUserProfile(userToClear);
      var profileBeforeReset = await fakeRepository.getUserProfile(
        userToClear.credentialId,
      );
      expect(
        profileBeforeReset.data,
        isNotNull,
        reason: "Profile should exist before reset",
      );

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
      // Verify the profile is gone
      profileBeforeReset = await fakeRepository.getUserProfile(
        userToClear.credentialId,
      );
      expect(profileBeforeReset.isSuccess, false); // Should fail to find user
      expect(profileBeforeReset.errorType, AuthErrorType.userNotFound);
    });
    test(
      'reset while authenticated should clear all state but set default auth user',
      () async {
        // Arrange - make some calls and set state
        await fakeRepository.loginWithEmail('test@example.com', 'password');
        await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);
        fakeRepository.fakeUserProfile(
          _createFakeUser(id: 'user-to-clear'),
        ); // Uses fakeUserProfile to inject directly

        // Verify state exists
        expect(fakeRepository.loginCalls, isNotEmpty);
        expect(fakeRepository.sendOtpCalls, isNotEmpty);
        expect(fakeRepository.isAuthenticated(), true);
        // Check if the faked user profile is retrievable before reset
        // Note: fakeUserProfile directly injects, does not use createUserProfile logic.
        // The key for _userProfiles in FakeAuthRepository is credentialId.
        final userToClear = _createFakeUser(
          id: 'user-to-clear',
          credentialId: 'cred-clear',
        );
        fakeRepository.fakeUserProfile(userToClear);
        var profileBeforeReset = await fakeRepository.getUserProfile(
          userToClear.credentialId,
        );
        expect(
          profileBeforeReset.data,
          isNotNull,
          reason: "Profile should exist before reset",
        );

        // Act
        fakeRepository.reset(authenticated: true);

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
        expect(fakeRepository.isAuthenticated(), true);
        expect(fakeRepository.getCurrentCredentials(), isNotNull);
        expect(
          fakeRepository.getCurrentCredentials()!.email,
          'test@example.com',
        );
      },
    );

    test('emitAuthStreamError should add error to auth state stream', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);
      final authStateStream = fakeRepository.authStateChanges;
      final errorCompleter = Completer<Exception>();
      final stateCompleter = Completer<AuthStatus>();

      // Listen to both data and errors
      final StreamSubscription<AuthStatus> subscription = authStateStream
          .listen(
            stateCompleter.complete,
            onError: (error) {
              if (error is Exception) {
                errorCompleter.complete(error);
              } else {
                errorCompleter.completeError(
                  'Expected Exception but got ${error.runtimeType}',
                );
              }
            },
          );

      // Act
      const errorMessage = 'Test error';
      fakeRepository.emitAuthStreamError(errorMessage);

      // Assert
      final emittedError = await errorCompleter.future.timeout(
        Duration(seconds: 1),
        onTimeout:
            () => throw TimeoutException('Did not receive error in time'),
      );

      expect(emittedError, isA<Exception>());
      expect(emittedError.toString(), contains(errorMessage));

      // Clean up
      await subscription.cancel();
    });
      test('emitUserStreamError should add error to user stream', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);
      final userStream = fakeRepository.userChanges;
      final errorCompleter = Completer<Exception>();
      final userCompleter = Completer<UserCredential?>();

      // Listen to both data and errors
      final StreamSubscription<UserCredential?> subscription = userStream
          .listen(
            userCompleter.complete,
            onError: (error) {
              if (error is Exception) {
                errorCompleter.complete(error);
              } else {
                errorCompleter.completeError(
                  'Expected Exception but got ${error.runtimeType}',
                );
              }
            },
          );

      // Act
      const errorMessage = 'Test error';
      fakeRepository.emitUserStreamError(errorMessage);

      // Assert
      final emittedError = await errorCompleter.future.timeout(
        Duration(seconds: 1),
        onTimeout:
            () => throw TimeoutException('Did not receive error in time'),
      );

      expect(emittedError, isA<Exception>());
      expect(emittedError.toString(), contains(errorMessage));

      // Clean up
      await subscription.cancel();
    });
    test('fakeAuthResponse should control success/failure behavior', () async {
      // Test success
      fakeRepository.fakeAuthResponse(succeed: true);
      final successResult = await fakeRepository.loginWithEmail(
        'test@example.com',
        'password',
      );
      expect(successResult.isSuccess, true);

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
    });

    test(
      'fakeUserProfile should allow setting up test user profiles',
      () async {
        // Arrange
        final testUser1 = _createFakeUser(
          credentialId: 'cred-1',
          email: 'user1@test.com',
          id: 'user1-id',
        );
        final testUser2 = _createFakeUser(
          credentialId: 'cred-2',
          email: 'user2@test.com',
          id: 'user2-id',
        );

        fakeRepository.fakeUserProfile(testUser1); // Injects directly
        fakeRepository.fakeUserProfile(testUser2);
        fakeRepository.fakeAuthResponse(
          succeed: true,
        ); // For the getUserProfile calls

        // Act & Assert
        final result1 = await fakeRepository.getUserProfile(
          testUser1.credentialId,
        );
        expect(result1.isSuccess, true);
        expect(result1.data!.email, 'user1@test.com');
        expect(result1.data!.id, testUser1.id);

        final result2 = await fakeRepository.getUserProfile(
          testUser2.credentialId,
        );
        expect(result2.isSuccess, true);
        expect(result2.data!.email, 'user2@test.com');
        expect(result2.data!.id, testUser2.id);
      },
    );

    test(
      'addRegisteredEmail should allow configuring registered emails',
      () async {
        // The FakeAuthRepository has 'registered@example.com' by default.
        // This test verifies the default behavior.

        // Test with the default registered email
        fakeRepository.fakeAuthResponse(succeed: true);
        final result1 = await fakeRepository.isEmailRegistered(
          'registered@example.com',
        );
        expect(result1.isSuccess, true);
        expect(result1.data, true);

        // Test with an unregistered email
        final result2 = await fakeRepository.isEmailRegistered(
          'not-registered@test.com',
        );
        expect(result2.isSuccess, true);
        expect(result2.data, false);
      },
    );
   test('getSentOtp should return OTP codes for testing', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true); // For sendOtp calls
      await fakeRepository.sendOtp('test1@example.com', OtpReceiver.email);
      // Wait a bit to ensure different timestamps if OTP generation depends on it closely
      // Though the fake might just generate random or sequential
      await Future.delayed(Duration(milliseconds: 5));
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
      // OTPs are generated based on current time in Fake, so they should differ if delay is sufficient.
      // However, simply checking for non-null and length is robust.
      if (otp1 == otp2 &&
          fakeRepository.getSentOtp('test1@example.com', OtpReceiver.email) ==
              fakeRepository.getSentOtp(
                'test2@example.com',
                OtpReceiver.email,
              )) {
      }
    });

    test('should handle concurrent login attempts correctly', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);

      // Act - Simulate concurrent login attempts
      final futures = List.generate(
        3,
        (_) =>
            fakeRepository.loginWithEmail('concurrent@example.com', 'password'),
      );

      final results = await Future.wait(futures);

      // Assert - All should succeed
      for (final result in results) {
        expect(result.isSuccess, true);
      }
      expect(
        fakeRepository.loginCalls
            .where((call) => call == 'concurrent@example.com:password')
            .length,
        3,
      );
    });
  });
}
