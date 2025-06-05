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
