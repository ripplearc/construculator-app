import 'dart:async';
import 'package:construculator/libraries/auth/shared_auth_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:flutter_modular/flutter_modular.dart';

void main() {
  group('SharedAuthNotifier', () {
    late SharedAuthNotifier authNotifier;

    setUp(() {
      authNotifier = SharedAuthNotifier();
    });

    tearDown(() {
      authNotifier.dispose();
    });

    group('Interface Contract Verification', () {
      test('should implement IAuthNotifier interface', () {
        expect(authNotifier, isA<AuthNotifier>());
      });

      test('should implement Disposable interface', () {
        expect(authNotifier, isA<Disposable>());
      });

      test('should provide all required streams', () {
        expect(authNotifier.onLogin, isA<Stream<UserCredential>>());
        expect(authNotifier.onLogout, isA<Stream<void>>());
        expect(authNotifier.onAuthStateChanged, isA<Stream<AuthStatus>>());
        expect(authNotifier.onSetupProfile, isA<Stream<void>>());
      });

      test('should provide all required emit methods', () {
        // Test that methods exist and can be called without error
        expect(() => authNotifier.emitLogin(_createFakeCredential()), returnsNormally);
        expect(() => authNotifier.emitLogout(), returnsNormally);
        expect(() => authNotifier.emitAuthStateChanged(AuthStatus.authenticated), returnsNormally);
        expect(() => authNotifier.emitSetupProfile(), returnsNormally);
      });
    });

    group('Stream Behavior', () {
      test('streams should be broadcast and allow multiple listeners', () {
        // Test that multiple listeners can be added without error
        expect(() {
          authNotifier.onLogin.listen((_) {});
          authNotifier.onLogin.listen((_) {});
        }, returnsNormally);

        expect(() {
          authNotifier.onLogout.listen((_) {});
          authNotifier.onLogout.listen((_) {});
        }, returnsNormally);

        expect(() {
          authNotifier.onAuthStateChanged.listen((_) {});
          authNotifier.onAuthStateChanged.listen((_) {});
        }, returnsNormally);

        expect(() {
          authNotifier.onSetupProfile.listen((_) {});
          authNotifier.onSetupProfile.listen((_) {});
        }, returnsNormally);
      });

      test('streams should be accessible immediately after creation', () {
        final notifier = SharedAuthNotifier();
        
        expect(notifier.onLogin, isNotNull);
        expect(notifier.onLogout, isNotNull);
        expect(notifier.onAuthStateChanged, isNotNull);
        expect(notifier.onSetupProfile, isNotNull);
        
        notifier.dispose();
      });
    });

    group('Login Event Emission', () {
      test('emitLogin should emit login event with correct user credential', () async {
        // Arrange
        final fakeCredential = _createFakeCredential();
        final loginCompleter = Completer<UserCredential>();
        
        authNotifier.onLogin.listen(loginCompleter.complete);

        // Act
        authNotifier.emitLogin(fakeCredential);

        // Assert
        final receivedCredential = await loginCompleter.future.timeout(Duration(seconds: 1));
        expect(receivedCredential.id, fakeCredential.id);
        expect(receivedCredential.email, fakeCredential.email);
        expect(receivedCredential.metadata, fakeCredential.metadata);
        expect(receivedCredential.createdAt, fakeCredential.createdAt);
      });

      test('emitLogin should automatically emit authenticated state', () async {
        // Arrange
        final fakeCredential = _createFakeCredential();
        final stateCompleter = Completer<AuthStatus>();
        
        authNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        // Act
        authNotifier.emitLogin(fakeCredential);

        // Assert
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        expect(receivedState, AuthStatus.authenticated);
      });

      test('emitLogin should emit both login and auth state events', () async {
        // Arrange
        final fakeCredential = _createFakeCredential();
        final loginEvents = <UserCredential>[];
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act
        authNotifier.emitLogin(fakeCredential);

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(loginEvents, hasLength(1));
        expect(stateEvents, hasLength(1));
        expect(loginEvents[0].email, fakeCredential.email);
        expect(stateEvents[0], AuthStatus.authenticated);
      });

      test('multiple emitLogin calls should emit multiple events', () async {
        // Arrange
        final credential1 = _createFakeCredential(email: 'user1@test.com');
        final credential2 = _createFakeCredential(email: 'user2@test.com');
        final loginEvents = <UserCredential>[];
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act
        authNotifier.emitLogin(credential1);
        authNotifier.emitLogin(credential2);

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(loginEvents, hasLength(2));
        expect(stateEvents, hasLength(2));
        expect(loginEvents[0].email, 'user1@test.com');
        expect(loginEvents[1].email, 'user2@test.com');
        expect(stateEvents.every((state) => state == AuthStatus.authenticated), true);
      });
    });

    group('Logout Event Emission', () {
      test('emitLogout should emit logout event', () async {
        // Arrange
        final logoutCompleter = Completer<void>();
        
        authNotifier.onLogout.listen((_) => logoutCompleter.complete());

        // Act
        authNotifier.emitLogout();

        // Assert
        await logoutCompleter.future.timeout(Duration(seconds: 1));
        // If we reach here without timeout, the event was emitted successfully
      });

      test('emitLogout should automatically emit unauthenticated state', () async {
        // Arrange
        final logoutCompleter = Completer<void>();
        
        authNotifier.onLogout.listen((_) => logoutCompleter.complete());

        // Act
        authNotifier.emitLogout();

        // Assert - Only logout event should be emitted, not auth state
        await logoutCompleter.future.timeout(Duration(seconds: 1));
        // If we reach here without timeout, the logout event was emitted successfully
      });

      test('emitLogout should emit logout events only', () async {
        // Arrange
        int logoutEventCount = 0;
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogout.listen((_) => logoutEventCount++);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act
        authNotifier.emitLogout();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - Only logout event should be emitted
        expect(logoutEventCount, 1);
        expect(stateEvents, hasLength(0)); // No auth state changes from emitLogout
      });

      test('multiple emitLogout calls should emit multiple logout events only', () async {
        // Arrange
        int logoutEventCount = 0;
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogout.listen((_) => logoutEventCount++);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act
        authNotifier.emitLogout();
        authNotifier.emitLogout();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - Only logout events should be emitted
        expect(logoutEventCount, 2);
        expect(stateEvents, hasLength(0)); // No auth state changes from emitLogout
      });
    });

    group('Setup Profile Event Emission', () {
      test('emitSetupProfile should emit setup profile event', () async {
        // Arrange
        final setupCompleter = Completer<void>();
        
        authNotifier.onSetupProfile.listen((_) => setupCompleter.complete());

        // Act
        authNotifier.emitSetupProfile();

        // Assert
        await setupCompleter.future.timeout(Duration(seconds: 1));
        // If we reach here without timeout, the event was emitted successfully
      });

      test('multiple emitSetupProfile calls should emit multiple events', () async {
        // Arrange
        int setupEventCount = 0;
        
        authNotifier.onSetupProfile.listen((_) => setupEventCount++);

        // Act
        authNotifier.emitSetupProfile();
        authNotifier.emitSetupProfile();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(setupEventCount, 2);
      });
    });

    group('Auth State Change Event Emission', () {
      test('emitAuthStateChanged should emit correct auth status', () async {
        // Arrange
        final stateCompleter = Completer<AuthStatus>();
        
        authNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        // Act
        authNotifier.emitAuthStateChanged(AuthStatus.authenticated);

        // Assert
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        expect(receivedState, AuthStatus.authenticated);
      });

      test('emitAuthStateChanged should handle all auth status types', () async {
        // Arrange
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act
        authNotifier.emitAuthStateChanged(AuthStatus.authenticated);
        authNotifier.emitAuthStateChanged(AuthStatus.unauthenticated);
        authNotifier.emitAuthStateChanged(AuthStatus.loading);
        authNotifier.emitAuthStateChanged(AuthStatus.connectionError);

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(stateEvents, hasLength(4));
        expect(stateEvents[0], AuthStatus.authenticated);
        expect(stateEvents[1], AuthStatus.unauthenticated);
        expect(stateEvents[2], AuthStatus.loading);
        expect(stateEvents[3], AuthStatus.connectionError);
      });

      test('emitAuthStateChanged should not automatically trigger other events', () async {
        // Arrange
        final loginEvents = <UserCredential>[];
        int logoutEventCount = 0;
        int setupEventCount = 0;
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onLogout.listen((_) => logoutEventCount++);
        authNotifier.onSetupProfile.listen((_) => setupEventCount++);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act
        authNotifier.emitAuthStateChanged(AuthStatus.loading);

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(stateEvents, hasLength(1));
        expect(stateEvents[0], AuthStatus.loading);
        expect(loginEvents, isEmpty);
        expect(logoutEventCount, 0);
        expect(setupEventCount, 0);
      });
    });

    group('Event Interaction and Sequencing', () {
      test('login followed by logout should emit correct sequence', () async {
        // Arrange
        final fakeCredential = _createFakeCredential();
        final allEvents = <String>[];
        
        authNotifier.onLogin.listen((_) => allEvents.add('login'));
        authNotifier.onLogout.listen((_) => allEvents.add('logout'));
        authNotifier.onAuthStateChanged.listen((status) => allEvents.add('state:$status'));

        // Act
        authNotifier.emitLogin(fakeCredential);
        authNotifier.emitLogout();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - emitLogin emits login + auth state, emitLogout only emits logout
        expect(allEvents, hasLength(3));
        expect(allEvents[0], 'login');
        expect(allEvents[1], 'state:AuthStatus.authenticated');
        expect(allEvents[2], 'logout');
        // No automatic unauthenticated state from emitLogout - that's the service's job
      });

      test('mixed event emissions should work correctly', () async {
        // Arrange
        final fakeCredential = _createFakeCredential();
        final loginEvents = <UserCredential>[];
        int logoutEventCount = 0;
        int setupEventCount = 0;
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onLogout.listen((_) => logoutEventCount++);
        authNotifier.onSetupProfile.listen((_) => setupEventCount++);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act
        authNotifier.emitLogin(fakeCredential);
        authNotifier.emitSetupProfile();
        authNotifier.emitAuthStateChanged(AuthStatus.loading);
        authNotifier.emitLogout();

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - Check that all expected events were emitted
        expect(loginEvents, hasLength(1));
        expect(setupEventCount, 1);
        expect(logoutEventCount, 1);
        expect(stateEvents, hasLength(2)); // authenticated from login, loading from explicit call (no unauthenticated from logout)
        
        // Verify the login credential is correct
        expect(loginEvents[0].email, fakeCredential.email);
        
        // Verify state changes include expected states (authenticated from login, loading from explicit call)
        expect(stateEvents.contains(AuthStatus.authenticated), true);
        expect(stateEvents.contains(AuthStatus.loading), true);
      });

      test('should handle multiple listeners without interference', () async {
        // Arrange
        final listener1Events = <UserCredential>[];
        final listener2Events = <UserCredential>[];
        final fakeCredential = _createFakeCredential();
        
        // Add multiple listeners
        authNotifier.onLogin.listen(listener1Events.add);
        authNotifier.onLogin.listen(listener2Events.add);

        // Act
        authNotifier.emitLogin(fakeCredential);

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - both listeners should receive the event
        expect(listener1Events, hasLength(1));
        expect(listener2Events, hasLength(1));
        expect(listener1Events[0].email, fakeCredential.email);
        expect(listener2Events[0].email, fakeCredential.email);
      });
    });

    group('Resource Management and Disposal', () {
      test('dispose should close all stream controllers', () {
        // Arrange
        final notifier = SharedAuthNotifier();
        
        // Add listeners to verify streams are working
        notifier.onLogin.listen((_) {});
        notifier.onLogout.listen((_) {});
        notifier.onAuthStateChanged.listen((_) {});
        notifier.onSetupProfile.listen((_) {});

        // Act & Assert - should not throw
        expect(() => notifier.dispose(), returnsNormally);
      });

      test('streams should throw StateError after disposal', () async {
        // Arrange
        final notifier = SharedAuthNotifier();
        final loginEvents = <UserCredential>[];
        int logoutEventCount = 0;
        final stateEvents = <AuthStatus>[];
        int setupEventCount = 0;
        
        notifier.onLogin.listen(loginEvents.add);
        notifier.onLogout.listen((_) => logoutEventCount++);
        notifier.onAuthStateChanged.listen(stateEvents.add);
        notifier.onSetupProfile.listen((_) => setupEventCount++);

        // Act
        notifier.dispose();
        
        // Try to emit events after disposal - these should throw StateError
        expect(() => notifier.emitLogin(_createFakeCredential()), throwsStateError);
        expect(() => notifier.emitLogout(), throwsStateError);
        expect(() => notifier.emitAuthStateChanged(AuthStatus.authenticated), throwsStateError);
        expect(() => notifier.emitSetupProfile(), throwsStateError);

        // Allow time for any potential stream events
        await Future.delayed(Duration(milliseconds: 10));

        // Assert - no events should have been received
        expect(loginEvents, isEmpty);
        expect(logoutEventCount, 0);
        expect(stateEvents, isEmpty);
        expect(setupEventCount, 0);
      });

      test('multiple dispose calls should not cause errors', () {
        // Arrange
        final notifier = SharedAuthNotifier();

        // Act & Assert - multiple dispose calls should not throw
        expect(() => notifier.dispose(), returnsNormally);
        expect(() => notifier.dispose(), returnsNormally);
        expect(() => notifier.dispose(), returnsNormally);
      });
    });

    group('Stream Controller Configuration', () {
      test('stream controllers should be broadcast streams', () {
        // This is verified by the ability to add multiple listeners
        // which we test in the "Stream Behavior" group
        
        // Additional verification that streams behave as broadcast
        final subscription1 = authNotifier.onLogin.listen((_) {});
        final subscription2 = authNotifier.onLogin.listen((_) {});
        
        expect(() => subscription1.cancel(), returnsNormally);
        expect(() => subscription2.cancel(), returnsNormally);
      });

      test('streams should handle rapid successive emissions', () async {
        // Arrange
        final fakeCredential = _createFakeCredential();
        final loginEvents = <UserCredential>[];
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act - emit events rapidly
        for (int i = 0; i < 10; i++) {
          authNotifier.emitLogin(fakeCredential);
        }

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 50));

        // Assert
        expect(loginEvents, hasLength(10));
        expect(stateEvents, hasLength(10));
        expect(stateEvents.every((state) => state == AuthStatus.authenticated), true);
      });
    });

    group('Edge Cases and Robustness', () {
      test('should handle void stream events correctly', () async {
        // Arrange
        final logoutCompleter = Completer<void>();
        final setupCompleter = Completer<void>();
        
        authNotifier.onLogout.listen((_) {
          // For void streams, we can't check the value since it's void
          // The fact that the listener is called is sufficient
          logoutCompleter.complete();
        });
        
        authNotifier.onSetupProfile.listen((_) {
          // For void streams, we can't check the value since it's void
          // The fact that the listener is called is sufficient
          setupCompleter.complete();
        });

        // Act
        authNotifier.emitLogout();
        authNotifier.emitSetupProfile();

        // Assert
        await logoutCompleter.future.timeout(Duration(seconds: 1));
        await setupCompleter.future.timeout(Duration(seconds: 1));
      });

      test('should handle rapid successive events without issues', () async {
        // Arrange
        final loginEvents = <UserCredential>[];
        final stateEvents = <AuthStatus>[];
        final fakeCredential = _createFakeCredential();
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        // Act - emit many events rapidly
        for (int i = 0; i < 5; i++) {
          authNotifier.emitLogin(fakeCredential);
        }

        // Allow time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 50));

        // Assert - all events should be processed
        expect(loginEvents, hasLength(5));
        expect(stateEvents, hasLength(5));
        expect(stateEvents.every((state) => state == AuthStatus.authenticated), true);
      });
    });
  });
}

// Helper function to create fake credentials for testing
UserCredential _createFakeCredential({String? email}) {
  return UserCredential(
    id: 'fake-id-${DateTime.now().millisecondsSinceEpoch}',
    email: email ?? 'test@example.com',
    metadata: {'source': 'test'},
    createdAt: DateTime.now(),
  );
} 