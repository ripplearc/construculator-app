import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  group('FakeAuthNotifier', () {
    late FakeAuthNotifier fakeNotifier;

    setUp(() {
      fakeNotifier = FakeAuthNotifier();
    });

    tearDown(() {
      fakeNotifier.dispose();
    });

    group('Interface Contract Verification', () {
      test('should implement IAuthNotifier interface', () {
        expect(fakeNotifier, isA<IAuthNotifier>());
      });

      test('should provide all required streams', () {
        expect(fakeNotifier.onLogin, isA<Stream<UserCredential>>());
        expect(fakeNotifier.onLogout, isA<Stream<void>>());
        expect(fakeNotifier.onAuthStateChanged, isA<Stream<AuthStatus>>());
        expect(fakeNotifier.onSetupProfile, isA<Stream<void>>());
      });

      test('should provide all required emit methods', () {
        // Test that methods exist and can be called without error
        expect(() => fakeNotifier.emitLogin(_createFakeCredential()), returnsNormally);
        expect(() => fakeNotifier.emitLogout(), returnsNormally);
        expect(() => fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated), returnsNormally);
        expect(() => fakeNotifier.emitSetupProfile(), returnsNormally);
      });
    });

    group('Core Functionality', () {
      test('emitLogin should emit login event and authenticated state', () async {
        // Arrange
        final fakeCredential = _createFakeCredential();
        final loginCompleter = Completer<UserCredential>();
        final stateCompleter = Completer<AuthStatus>();
        
        fakeNotifier.onLogin.listen(loginCompleter.complete);
        fakeNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        // Act
        fakeNotifier.emitLogin(fakeCredential);

        // Assert
        final receivedCredential = await loginCompleter.future.timeout(Duration(seconds: 1));
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        
        expect(receivedCredential.email, fakeCredential.email);
        expect(receivedState, AuthStatus.authenticated);
      });

      test('emitLogout should emit logout event only', () async {
        // Arrange
        final logoutCompleter = Completer<void>();
        
        fakeNotifier.onLogout.listen((_) => logoutCompleter.complete());

        // Act
        fakeNotifier.emitLogout();

        // Assert - Only logout event should be emitted
        await logoutCompleter.future.timeout(Duration(seconds: 1));
        // If we reach here without timeout, the logout event was emitted successfully
      });

      test('emitSetupProfile should emit setup profile event and authenticated state', () async {
        // Arrange
        final setupCompleter = Completer<void>();
        final stateCompleter = Completer<AuthStatus>();
        
        fakeNotifier.onSetupProfile.listen((_) => setupCompleter.complete());
        fakeNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        // Act
        fakeNotifier.emitSetupProfile();

        // Assert
        await setupCompleter.future.timeout(Duration(seconds: 1));
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        
        expect(receivedState, AuthStatus.authenticated);
      });

      test('emitAuthStateChanged should emit correct auth state', () async {
        // Arrange
        final stateCompleter = Completer<AuthStatus>();
        fakeNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        // Act
        fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated);

        // Assert
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        expect(receivedState, AuthStatus.authenticated);
      });
    });

    group('Test Utility Features', () {
      test('should track login events for test verification', () async {
        // Arrange
        final credential1 = _createFakeCredential(email: 'user1@test.com');
        final credential2 = _createFakeCredential(email: 'user2@test.com');

        // Act
        fakeNotifier.emitLogin(credential1);
        fakeNotifier.emitLogin(credential2);

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(fakeNotifier.loginEvents, hasLength(2));
        expect(fakeNotifier.loginEvents[0].email, 'user1@test.com');
        expect(fakeNotifier.loginEvents[1].email, 'user2@test.com');
      });

      test('should track logout events for test verification', () async {
        // Act
        fakeNotifier.emitLogout();
        fakeNotifier.emitLogout();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(fakeNotifier.logoutEvents, hasLength(2));
      });

      test('should track auth state change events for test verification', () async {
        // Act
        fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated);
        fakeNotifier.emitAuthStateChanged(AuthStatus.unauthenticated);
        fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated);

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(fakeNotifier.stateChangedEvents, hasLength(3));
        expect(fakeNotifier.stateChangedEvents[0], AuthStatus.authenticated);
        expect(fakeNotifier.stateChangedEvents[1], AuthStatus.unauthenticated);
        expect(fakeNotifier.stateChangedEvents[2], AuthStatus.authenticated);
      });

      test('should track setup profile events for test verification', () async {
        // Act
        fakeNotifier.emitSetupProfile();
        fakeNotifier.emitSetupProfile();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(fakeNotifier.setupProfileEvents, hasLength(2));
      });

      test('emitLogin should trigger both login and auth state events', () async {
        // Act
        fakeNotifier.emitLogin(_createFakeCredential());

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - emitLogin should trigger both events
        expect(fakeNotifier.loginEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents[0], AuthStatus.authenticated);
      });

      test('emitLogout should trigger logout events only', () async {
        // Act
        fakeNotifier.emitLogout();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - emitLogout should only trigger logout events, not auth state
        expect(fakeNotifier.logoutEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents, hasLength(0)); // No automatic auth state changes
      });

      test('emitSetupProfile should trigger both setup profile and auth state events', () async {
        // Act
        fakeNotifier.emitSetupProfile();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - emitSetupProfile should trigger both events
        expect(fakeNotifier.setupProfileEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents[0], AuthStatus.authenticated);
      });

      test('reset should clear all tracked events', () async {
        // Arrange - add some events first
        fakeNotifier.emitLogin(_createFakeCredential());
        fakeNotifier.emitLogout();
        fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated);
        fakeNotifier.emitSetupProfile();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Verify events exist
        expect(fakeNotifier.loginEvents, isNotEmpty);
        expect(fakeNotifier.logoutEvents, isNotEmpty);
        expect(fakeNotifier.stateChangedEvents, isNotEmpty);
        expect(fakeNotifier.setupProfileEvents, isNotEmpty);

        // Act
        fakeNotifier.reset();

        // Assert
        expect(fakeNotifier.loginEvents, isEmpty);
        expect(fakeNotifier.logoutEvents, isEmpty);
        expect(fakeNotifier.stateChangedEvents, isEmpty);
        expect(fakeNotifier.setupProfileEvents, isEmpty);
      });
    });

    group('Stream Behavior', () {
      test('streams should be broadcast and allow multiple listeners', () {
        // Test that multiple listeners can be added without error
        expect(() {
          fakeNotifier.onLogin.listen((_) {});
          fakeNotifier.onLogin.listen((_) {});
        }, returnsNormally);

        expect(() {
          fakeNotifier.onLogout.listen((_) {});
          fakeNotifier.onLogout.listen((_) {});
        }, returnsNormally);

        expect(() {
          fakeNotifier.onAuthStateChanged.listen((_) {});
          fakeNotifier.onAuthStateChanged.listen((_) {});
        }, returnsNormally);

        expect(() {
          fakeNotifier.onSetupProfile.listen((_) {});
          fakeNotifier.onSetupProfile.listen((_) {});
        }, returnsNormally);
      });
    });

    group('Resource Management', () {
      test('dispose should close all streams without error', () {
        // Arrange - add listeners to streams
        fakeNotifier.onLogin.listen((_) {});
        fakeNotifier.onLogout.listen((_) {});
        fakeNotifier.onAuthStateChanged.listen((_) {});
        fakeNotifier.onSetupProfile.listen((_) {});

        // Act & Assert - should not throw
        expect(() => fakeNotifier.dispose(), returnsNormally);
      });
    });
  });
}

// Helper function to create fake credentials for testing
UserCredential _createFakeCredential({String? email}) {
  return UserCredential(
    id: 'fake-id',
    email: email ?? 'test@example.com',
    metadata: {'source': 'test'},
    createdAt: DateTime.now(),
  );
} 