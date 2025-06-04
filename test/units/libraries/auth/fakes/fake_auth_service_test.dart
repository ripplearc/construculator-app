import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/interfaces/auth_service.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

void main() {
  group('FakeAuthService', () {
    late FakeAuthService fakeService;
    late FakeAuthNotifier fakeNotifier;

    setUp(() {
      fakeNotifier = FakeAuthNotifier();
      fakeService = FakeAuthService(notifier: fakeNotifier);
    });

    tearDown(() {
      fakeService.dispose();
      fakeNotifier.dispose();
    });

    group('Interface Contract Verification', () {
      test('should implement IAuthService interface', () {
        expect(fakeService, isA<IAuthService>());
      });

      test('should provide all required authentication methods', () async {
        // Test that all interface methods exist and can be called
        expect(await fakeService.loginWithEmail('test@example.com', 'password'), isA<bool>());
        expect(await fakeService.registerWithEmail('test@example.com', 'password'), isA<bool>());
        expect(await fakeService.sendOtp('test@example.com', OtpReceiver.email), isA<bool>());
        expect(await fakeService.verifyOtp('test@example.com', '123456', OtpReceiver.email), isA<bool>());
        expect(await fakeService.resetPassword('test@example.com'), isA<bool>());
        expect(await fakeService.isEmailRegistered('test@example.com'), isA<bool>());
        expect(() => fakeService.logout(), returnsNormally);
        expect(fakeService.isAuthenticated(), isA<bool>());
        expect(await fakeService.getUserInfo(), isA<User?>());
        expect(await fakeService.getCurrentUser(), isA<UserCredential?>());
        expect(fakeService.authStateChanges, isA<Stream<AuthStatus>>());
      });
    });

    group('Core Authentication Functionality', () {
      test('loginWithEmail should succeed when configured to succeed', () async {
        // Arrange
        fakeService.loginShouldSucceed = true;

        // Act
        final result = await fakeService.loginWithEmail('test@example.com', 'password');

        // Assert
        expect(result, true);
        expect(fakeService.isAuthenticated(), true);
        expect(fakeService.loginCalls, contains('test@example.com:password'));
      });

      test('loginWithEmail should fail when configured to fail', () async {
        // Arrange
        fakeService.loginShouldSucceed = false;

        // Act
        final result = await fakeService.loginWithEmail('test@example.com', 'password');

        // Assert
        expect(result, false);
        expect(fakeService.isAuthenticated(), false);
        expect(fakeService.loginCalls, contains('test@example.com:password'));
      });

      test('registerWithEmail should succeed when configured to succeed', () async {
        // Arrange
        fakeService.loginShouldSucceed = true; // Same flag controls registration

        // Act
        final result = await fakeService.registerWithEmail('new@example.com', 'password');

        // Assert
        expect(result, true);
        expect(fakeService.isAuthenticated(), true);
        expect(fakeService.loginCalls, contains('register:new@example.com:password'));
      });

      test('logout should unauthenticate user and track calls', () async {
        // Arrange - start authenticated
        fakeService.setAuthenticated(true);
        expect(fakeService.isAuthenticated(), true);

        // Act
        await fakeService.logout();

        // Assert
        expect(fakeService.isAuthenticated(), false);
        expect(fakeService.logoutCallCount, 1);
      });

      test('isAuthenticated should reflect current authentication state', () {
        // Test unauthenticated state
        fakeService.setAuthenticated(false);
        expect(fakeService.isAuthenticated(), false);

        // Test authenticated state
        fakeService.setAuthenticated(true);
        expect(fakeService.isAuthenticated(), true);
      });
    });

    group('OTP Functionality', () {
      test('sendOtp should succeed when configured to succeed', () async {
        // Arrange
        fakeService.otpShouldSucceed = true;

        // Act
        final result = await fakeService.sendOtp('test@example.com', OtpReceiver.email);

        // Assert
        expect(result, true);
        expect(fakeService.otpSendCalls, contains('test@example.com:OtpReceiver.email'));
      });

      test('sendOtp should fail when configured to fail', () async {
        // Arrange
        fakeService.otpShouldSucceed = false;

        // Act
        final result = await fakeService.sendOtp('test@example.com', OtpReceiver.email);

        // Assert
        expect(result, false);
        expect(fakeService.otpSendCalls, contains('test@example.com:OtpReceiver.email'));
      });

      test('verifyOtp should succeed when configured to succeed', () async {
        // Arrange
        fakeService.otpShouldSucceed = true;

        // Act
        final result = await fakeService.verifyOtp('test@example.com', '123456', OtpReceiver.email);

        // Assert
        expect(result, true);
        expect(fakeService.isAuthenticated(), true);
        expect(fakeService.otpVerifyCalls, contains('test@example.com:123456:OtpReceiver.email'));
      });

      test('verifyOtp should fail when configured to fail', () async {
        // Arrange
        fakeService.otpShouldSucceed = false;

        // Act
        final result = await fakeService.verifyOtp('test@example.com', '123456', OtpReceiver.email);

        // Assert
        expect(result, false);
        expect(fakeService.isAuthenticated(), false);
        expect(fakeService.otpVerifyCalls, contains('test@example.com:123456:OtpReceiver.email'));
      });
    });

    group('Password Reset Functionality', () {
      test('resetPassword should succeed when configured to succeed', () async {
        // Arrange
        fakeService.resetPasswordShouldSucceed = true;

        // Act
        final result = await fakeService.resetPassword('test@example.com');

        // Assert
        expect(result, true);
        expect(fakeService.resetPasswordCalls, contains('test@example.com'));
      });

      test('resetPassword should fail when configured to fail', () async {
        // Arrange
        fakeService.resetPasswordShouldSucceed = false;

        // Act
        final result = await fakeService.resetPassword('test@example.com');

        // Assert
        expect(result, false);
        expect(fakeService.resetPasswordCalls, contains('test@example.com'));
      });
    });

    group('Email Registration Check', () {
      test('isEmailRegistered should return true for registered emails', () async {
        // Arrange
        fakeService.emailCheckShouldSucceed = true;
        fakeService.registeredEmails.add('registered@example.com');

        // Act
        final result = await fakeService.isEmailRegistered('registered@example.com');

        // Assert
        expect(result, true);
        expect(fakeService.emailCheckCalls, contains('registered@example.com'));
      });

      test('isEmailRegistered should return false for unregistered emails', () async {
        // Arrange
        fakeService.emailCheckShouldSucceed = true;

        // Act
        final result = await fakeService.isEmailRegistered('notregistered@example.com');

        // Assert
        expect(result, false);
        expect(fakeService.emailCheckCalls, contains('notregistered@example.com'));
      });

      test('isEmailRegistered should fail when configured to fail', () async {
        // Arrange
        fakeService.emailCheckShouldSucceed = false;

        // Act
        final result = await fakeService.isEmailRegistered('any@example.com');

        // Assert
        expect(result, false);
        expect(fakeService.emailCheckCalls, contains('any@example.com'));
      });
    });

    group('User Information Retrieval', () {
      test('getCurrentUser should return credentials when authenticated', () async {
        // Arrange
        fakeService.setAuthenticated(true, email: 'test@example.com');

        // Act
        final credentials = await fakeService.getCurrentUser();

        // Assert
        expect(credentials, isNotNull);
        expect(credentials!.email, 'test@example.com');
        expect(fakeService.getCurrentUserCallCount, 1);
      });

      test('getCurrentUser should return null when not authenticated', () async {
        // Arrange
        fakeService.setAuthenticated(false);

        // Act
        final credentials = await fakeService.getCurrentUser();

        // Assert
        expect(credentials, isNull);
        expect(fakeService.getCurrentUserCallCount, 1);
      });

      test('getUserInfo should return user info when authenticated', () async {
        // Arrange
        fakeService.setAuthenticated(true, email: 'test@example.com');

        // Act
        final userInfo = await fakeService.getUserInfo();

        // Assert
        expect(userInfo, isNotNull);
        expect(userInfo!.email, 'test@example.com');
        expect(userInfo.firstName, 'Test');
        expect(userInfo.lastName, 'User');
      });

      test('getUserInfo should return null when not authenticated', () async {
        // Arrange
        fakeService.setAuthenticated(false);

        // Act
        final userInfo = await fakeService.getUserInfo();

        // Assert
        expect(userInfo, isNull);
      });
    });

    group('Test Utility Features', () {
      test('should track all method calls for test verification', () async {
        // Act - call various methods
        await fakeService.loginWithEmail('login@test.com', 'pass');
        await fakeService.sendOtp('otp@test.com', OtpReceiver.email);
        await fakeService.verifyOtp('verify@test.com', '123456', OtpReceiver.email);
        await fakeService.resetPassword('reset@test.com');
        await fakeService.isEmailRegistered('check@test.com');
        await fakeService.logout();
        await fakeService.getCurrentUser();

        // Assert - verify all calls were tracked
        expect(fakeService.loginCalls, contains('login@test.com:pass'));
        expect(fakeService.otpSendCalls, contains('otp@test.com:OtpReceiver.email'));
        expect(fakeService.otpVerifyCalls, contains('verify@test.com:123456:OtpReceiver.email'));
        expect(fakeService.resetPasswordCalls, contains('reset@test.com'));
        expect(fakeService.emailCheckCalls, contains('check@test.com'));
        expect(fakeService.logoutCallCount, 1);
        expect(fakeService.getCurrentUserCallCount, 1);
      });

      test('reset should clear all state and call tracking', () async {
        // Arrange - make some calls and set state
        await fakeService.loginWithEmail('test@example.com', 'password');
        await fakeService.sendOtp('test@example.com', OtpReceiver.email);
        fakeService.setAuthenticated(true);

        // Verify state exists
        expect(fakeService.loginCalls, isNotEmpty);
        expect(fakeService.otpSendCalls, isNotEmpty);
        expect(fakeService.isAuthenticated(), true);

        // Act
        fakeService.reset();

        // Assert - everything should be cleared
        expect(fakeService.loginCalls, isEmpty);
        expect(fakeService.otpSendCalls, isEmpty);
        expect(fakeService.otpVerifyCalls, isEmpty);
        expect(fakeService.resetPasswordCalls, isEmpty);
        expect(fakeService.emailCheckCalls, isEmpty);
        expect(fakeService.logoutCallCount, 0);
        expect(fakeService.getCurrentUserCallCount, 0);
        expect(fakeService.isAuthenticated(), false);
        
        // Control flags should be reset to defaults
        expect(fakeService.loginShouldSucceed, true);
        expect(fakeService.otpShouldSucceed, true);
        expect(fakeService.resetPasswordShouldSucceed, true);
        expect(fakeService.emailCheckShouldSucceed, true);
      });

      test('setAuthenticated should properly set authentication state', () async {
        // Test setting authenticated with custom email
        fakeService.setAuthenticated(true, email: 'custom@example.com');
        expect(fakeService.isAuthenticated(), true);
        
        final userInfo = await fakeService.getUserInfo();
        expect(userInfo!.email, 'custom@example.com');

        // Test setting unauthenticated
        fakeService.setAuthenticated(false);
        expect(fakeService.isAuthenticated(), false);
        expect(await fakeService.getUserInfo(), isNull);
      });

      test('registeredEmails set should be configurable for testing', () async {
        // Arrange
        fakeService.registeredEmails.clear();
        fakeService.registeredEmails.addAll(['user1@test.com', 'user2@test.com']);

        // Act & Assert
        expect(await fakeService.isEmailRegistered('user1@test.com'), true);
        expect(await fakeService.isEmailRegistered('user2@test.com'), true);
        expect(await fakeService.isEmailRegistered('user3@test.com'), false);
      });
    });

    group('Initial State Configuration', () {
      test('should start unauthenticated by default', () {
        final service = FakeAuthService(notifier: FakeAuthNotifier());
        expect(service.isAuthenticated(), false);
        service.dispose();
      });

      test('should start authenticated when initiallyAuthenticated is true', () async {
        final notifier = FakeAuthNotifier();
        final service = FakeAuthService(
          notifier: notifier, 
          initiallyAuthenticated: true,
        );
        
        expect(service.isAuthenticated(), true);
        
        final userInfo = await service.getUserInfo();
        expect(userInfo, isNotNull);
        expect(userInfo!.email, 'test@example.com');
        
        service.dispose();
        notifier.dispose();
      });
    });

    group('Stream Behavior', () {
      test('authStateChanges should emit state changes', () async {
        // Arrange
        final stateCompleter = Completer<AuthStatus>();
        fakeService.authStateChanges.listen(stateCompleter.complete);

        // Act
        await fakeService.loginWithEmail('test@example.com', 'password');

        // Assert
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        expect(receivedState, AuthStatus.authenticated);
      });
    });

    group('Resource Management', () {
      test('dispose should clean up resources without error', () {
        // Act & Assert - should not throw
        expect(() => fakeService.dispose(), returnsNormally);
      });
    });
  });
} 