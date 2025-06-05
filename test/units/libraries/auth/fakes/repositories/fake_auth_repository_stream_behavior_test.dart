import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    // Default to successful responses for actions that might trigger streams
    fakeRepository.fakeAuthResponse(succeed: true);
  });

  tearDown(() {
    fakeRepository.dispose();
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
} 